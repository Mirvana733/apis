const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, x-app-secret",
};

const MODELO_GEMINI = "gemini-3.6-flash";

function responder(datos, estado = 200) {
  return new Response(JSON.stringify(datos), {
    status: estado,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...CORS_HEADERS,
    },
  });
}

function escaparHtml(valor) {
  return String(valor ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function plantilla(titulo, contenido) {
  return `
  <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; padding: 24px;">
    <div style="background: linear-gradient(135deg, #28C2D1, #39D2C0 45%, #7C6CF0); border-radius: 18px; padding: 26px; text-align: center;">
      <h1 style="color: #ffffff; margin: 0; font-size: 28px;">Lulilu 💗</h1>
    </div>
    <div style="background: #ffffff; border-radius: 0 0 18px 18px; padding: 26px; border: 1px solid #e5e7eb; border-top: none;">
      <h2 style="color: #2d2f33; margin-top: 0;">${titulo}</h2>
      <div style="color: #4b5563; font-size: 15px; line-height: 1.6;">${contenido}</div>
    </div>
    <p style="text-align: center; color: #9ca3af; font-size: 12px;">Este correo fue enviado automáticamente por Lulilu.</p>
  </div>`;
}

async function enviarCorreo(datos, env) {
  const tipo = String(datos.tipo || "");
  const destinatario = String(datos.destinatario || "").trim();
  const nombre = String(datos.nombre || "").trim();

  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(destinatario)) {
    return responder({ok: false, error: "El correo no es válido."}, 400);
  }

  let asunto;
  let html;

  if (tipo === "bienvenida") {
    asunto = "¡Bienvenido a Lulilu! 💗";
    html = plantilla(
      "¡Cuenta creada! 🎉",
      `<p>Hola <strong>${escaparHtml(nombre)}</strong>,</p>
       <p>Se creó una cuenta de <strong>Lulilu</strong> con este correo electrónico.</p>
       <p>Ya puedes iniciar sesión y compartir con la comunidad.</p>`
    );
  } else if (tipo === "nuevo_ingreso") {
    asunto = "Nuevo inicio de sesión en tu cuenta Lulilu 🔒";
    html = plantilla(
      "Inicio de sesión detectado 🔒",
      `<p>Se inició sesión en tu cuenta de <strong>Lulilu</strong>.</p>
       <p><strong>Fecha y hora (UTC):</strong> ${new Date().toISOString().replace("T", " ").slice(0, 16)}</p>
       <p>Si fuiste tú, ignora este mensaje. Si no reconoces este acceso, cambia tu contraseña lo antes posible.</p>`
    );
  } else {
    return responder({ok: false, error: "Tipo de correo no válido."}, 400);
  }

  if (!env.BREVO_API_KEY) {
    return responder(
      {ok: false, error: "BREVO_API_KEY no configurada en el Worker."},
      500
    );
  }

  const respuesta = await fetch("https://api.brevo.com/v3/smtp/email", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "api-key": env.BREVO_API_KEY,
    },
    body: JSON.stringify({
      sender: {
        name: "Lulilu",
        email: env.REMITENTE || "zambranarojasluzmirvana@gmail.com",
      },
      to: [{email: destinatario, name: nombre || "usuario"}],
      subject: asunto,
      htmlContent: html,
    }),
  });

  if (!respuesta.ok) {
    const cuerpo = await respuesta.text();
    console.error("Brevo error:", cuerpo);
    return responder(
      {ok: false, error: `Brevo respondió ${respuesta.status}.`},
      502
    );
  }

  return responder({ok: true, enviado: true});
}

const PROMPT_BASE = `
Eres el moderador de contenido de la red social Lulilu.

Determina si el contenido contiene:
- insultos o lenguaje ofensivo
- amenazas
- contenido sexual inapropiado
- discurso de odio
- acoso
- spam o publicidad engañosa
- contenido peligroso o extremista

Responde únicamente JSON con este formato:
{"aprobado": true, "motivo": ""}
o
{"aprobado": false, "motivo": "razón breve"}

Sin texto adicional.
`;

async function moderarTexto(datos, env) {
  const tipo = String(datos.tipo || "texto");
  const texto = String(datos.texto || "").trim();

  if (texto.length === 0) {
    return responder({ok: true, aprobado: false, motivo: "Escribe algo para publicar."});
  }

  if (texto.length > 1000) {
    return responder({ok: true, aprobado: false, motivo: "El texto es demasiado largo."});
  }

  if (!env.GEMINI_API_KEY) {
    return responder(
      {ok: false, error: "GEMINI_API_KEY no configurada en el Worker."},
      500
    );
  }

  const tipoLabel = tipo === "comentario" ? "comentario" : "publicación de texto";

  const respuesta = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODELO_GEMINI}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": env.GEMINI_API_KEY,
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [{text: `${PROMPT_BASE}\n${tipoLabel}:\n${texto}`}],
          },
        ],
        generationConfig: {responseMimeType: "application/json"},
      }),
    }
  );

  if (!respuesta.ok) {
    const cuerpo = await respuesta.text();
    console.error("Gemini error:", cuerpo);
    return responder(
      {ok: false, error: `Gemini respondió ${respuesta.status}.`},
      502
    );
  }

  const data = await respuesta.json();
  const textoRespuesta = String(
    data?.candidates?.[0]?.content?.parts?.[0]?.text || ""
  )
    .replace(/```json|```/g, "")
    .trim();

  let aprobado = false;
  let motivo = "No se pudo determinar si el contenido es apropiado.";

  try {
    const parse = JSON.parse(textoRespuesta);
    aprobado = parse.aprobado === true;
    motivo = typeof parse.motivo === "string" ? parse.motivo.trim() : "";
  } catch (error) {
    const enTexto = textoRespuesta.toUpperCase();
    aprobado = !enTexto.includes("BLOQUEADO") && enTexto.includes("APROBADO");
  }

  return responder({ok: true, aprobado, motivo});
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {status: 204, headers: CORS_HEADERS});
    }

    const url = new URL(request.url);

    if (request.method !== "POST") {
      return responder({ok: false, error: "Método no permitido."}, 405);
    }

    if (
      !env.APP_SECRET ||
      request.headers.get("x-app-secret") !== env.APP_SECRET
    ) {
      return responder({ok: false, error: "No autorizado."}, 401);
    }

    let datos;
    try {
      datos = await request.json();
    } catch (error) {
      return responder(
        {ok: false, error: "El cuerpo de la solicitud no es JSON."},
        400
      );
    }

    try {
      switch (url.pathname) {
        case "/email":
          return enviarCorreo(datos, env);
        case "/moderar":
          return moderarTexto(datos, env);
        default:
          return responder({ok: false, error: "Ruta no encontrada."}, 404);
      }
    } catch (error) {
      console.error("Error interno:", error);
      return responder({ok: false, error: "Error interno del Worker."}, 500);
    }
  },
};