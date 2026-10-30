// Generación automática del "Top de la semana".
//
// Cloudflare Cron Triggers ejecuta `scheduled()` el domingo a las 00:00 de
// Bolivia (ver `wrangler.toml`). Este módulo cierra la semana que terminó
// (lunes 00:00 → domingo 00:00) y guarda el Top en Firestore a través de la
// API REST usando una cuenta de servicio. El resultado queda inmutable.
//
// Secreto requerido en el Worker:
//   FIREBASE_SERVICE_ACCOUNT = contenido completo del JSON de la cuenta de
//   servicio (project_id, client_email, private_key...).
//
// No requiere el plan Blaze de Firebase: solo permisos de Firestore.

const OFFSET_BOLIVIA_HORAS = 4; // Bolivia es UTC-4 (sin horario de verano).
const MILISEGUNDOS_DIA = 24 * 60 * 60 * 1000;
const MILISEGUNDOS_HORA = 60 * 60 * 1000;
const MAXIMO_RESULTADOS = 10;

function base64urlDesdeBytes(bytes) {
  let binario = "";
  for (let i = 0; i < bytes.length; i++) {
    binario += String.fromCharCode(bytes[i]);
  }
  return btoa(binario).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64urlDesdeTexto(texto) {
  return base64urlDesdeBytes(new TextEncoder().encode(texto));
}

function pemAArrayBuffer(pem) {
  const limpio = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");

  const binario = atob(limpio);
  const bytes = new Uint8Array(binario.length);
  for (let i = 0; i < binario.length; i++) {
    bytes[i] = binario.charCodeAt(i);
  }
  return bytes.buffer;
}

async function obtenerToken(env) {
  if (!env.FIREBASE_SERVICE_ACCOUNT) {
    throw new Error("Falta FIREBASE_SERVICE_ACCOUNT en el Worker.");
  }

  const cuenta = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  const ahora = Math.floor(Date.now() / 1000);

  const cabecera = base64urlDesdeTexto(
    JSON.stringify({ alg: "RS256", typ: "JWT" }),
  );

  const cuerpo = base64urlDesdeTexto(
    JSON.stringify({
      iss: cuenta.client_email,
      scope: "https://www.googleapis.com/auth/datastore",
      aud: "https://oauth2.googleapis.com/token",
      iat: ahora,
      exp: ahora + 3600,
    }),
  );

  const firma = `${cabecera}.${cuerpo}`;

  const llave = await crypto.subtle.importKey(
    "pkcs8",
    pemAArrayBuffer(cuenta.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const firmaBytes = new Uint8Array(
    await crypto.subtle.sign(
      { name: "RSASSA-PKCS1-v1_5" },
      llave,
      new TextEncoder().encode(firma),
    ),
  );

  const asercion = `${firma}.${base64urlDesdeBytes(firmaBytes)}`;

  const respuesta = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:
      "grant_type=" +
      encodeURIComponent("urn:ietf:params:oauth:grant-type:jwt-bearer") +
      "&assertion=" +
      asercion,
  });

  if (!respuesta.ok) {
    throw new Error(
      `No se pudo obtener el token de Google: ${respuesta.status} ${await respuesta.text()}`,
    );
  }

  const datos = await respuesta.json();
  return { token: datos.access_token, proyecto: cuenta.project_id };
}

// ==========================================
// CODIFICACIÓN / DECODIFICACIÓN FIRESTORE
// ==========================================

function decodificarValor(valor) {
  if (valor == null) return null;
  if ("stringValue" in valor) return valor.stringValue;
  if ("integerValue" in valor) return Number(valor.integerValue);
  if ("doubleValue" in valor) return valor.doubleValue;
  if ("booleanValue" in valor) return valor.booleanValue;
  if ("timestampValue" in valor) return valor.timestampValue;
  if ("nullValue" in valor) return null;
  if ("mapValue" in valor) return decodificarCampos(valor.mapValue.fields || {});
  if ("arrayValue" in valor) {
    return (valor.arrayValue.values || []).map(decodificarValor);
  }
  return null;
}

function decodificarCampos(campos) {
  const objeto = {};
  for (const [clave, valor] of Object.entries(campos)) {
    objeto[clave] = decodificarValor(valor);
  }
  return objeto;
}

function codificarValor(valor) {
  if (valor === null || valor === undefined) return { nullValue: null };
  if (typeof valor === "string") return { stringValue: valor };
  if (typeof valor === "boolean") return { booleanValue: valor };
  if (typeof valor === "number") {
    return Number.isInteger(valor)
      ? { integerValue: String(valor) }
      : { doubleValue: valor };
  }
  if (valor instanceof Date) return { timestampValue: valor.toISOString() };
  if (Array.isArray(valor)) {
    return { arrayValue: { values: valor.map(codificarValor) } };
  }
  if (typeof valor === "object") {
    return { mapValue: { fields: codificarCampos(valor) } };
  }
  return { nullValue: null };
}

function codificarCampos(objeto) {
  const campos = {};
  for (const [clave, valor] of Object.entries(objeto)) {
    campos[clave] = codificarValor(valor);
  }
  return campos;
}

async function listarColeccion(token, proyecto, coleccion) {
  const documentos = [];
  let paginaToken = "";

  do {
    const url =
      `https://firestore.googleapis.com/v1/projects/${proyecto}` +
      `/databases/(default)/documents/${coleccion}?pageSize=300` +
      (paginaToken ? `&pageToken=${encodeURIComponent(paginaToken)}` : "");

    const respuesta = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (!respuesta.ok) {
      throw new Error(
        `No se pudo leer ${coleccion}: ${respuesta.status} ${await respuesta.text()}`,
      );
    }

    const datos = await respuesta.json();

    for (const documento of datos.documents || []) {
      documentos.push({
        id: documento.name.split("/").pop(),
        ...decodificarCampos(documento.fields || {}),
      });
    }

    paginaToken = datos.nextPageToken || "";
  } while (paginaToken);

  return documentos;
}

async function escribirDocumento(token, proyecto, coleccion, id, campos) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${proyecto}` +
    `/databases/(default)/documents/${coleccion}/${id}`;

  const respuesta = await fetch(url, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ fields: codificarCampos(campos) }),
  });

  if (!respuesta.ok) {
    throw new Error(
      `No se pudo guardar el Top: ${respuesta.status} ${await respuesta.text()}`,
    );
  }
}

// ==========================================
// PERIODO
// ==========================================

async function existeDocumento(token, proyecto, coleccion, id) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${proyecto}` +
    `/databases/(default)/documents/${coleccion}/${id}`;

  const respuesta = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (respuesta.status === 404) return false;

  if (!respuesta.ok) {
    throw new Error(
      `No se pudo verificar ${coleccion}/${id}: ${respuesta.status} ` +
        `${await respuesta.text()}`,
    );
  }

  return true;
}

// ==========================================
// PERIODO
// ==========================================

function lunesDeSemanaLocal(momento) {
  const local = new Date(
    momento.getTime() - OFFSET_BOLIVIA_HORAS * MILISEGUNDOS_HORA,
  );
  const dia = (local.getUTCDay() + 6) % 7; // 0 = lunes

  const lunesLocal = Date.UTC(
    local.getUTCFullYear(),
    local.getUTCMonth(),
    local.getUTCDate() - dia,
    0,
    0,
    0,
  );

  return new Date(lunesLocal + OFFSET_BOLIVIA_HORAS * MILISEGUNDOS_HORA);
}

// Periodo que cierra en el momento de ejecución (domingo 00:00 de Bolivia).
// Va del lunes 00:00 al domingo 00:00 de la misma semana (6 días): cuenta las
// interacciones de lunes a sábado. El domingo es el día de publicación.
export function periodoQueCierra(ahora = new Date()) {
  const inicio = lunesDeSemanaLocal(ahora);
  const fin = new Date(inicio.getTime() + 6 * MILISEGUNDOS_DIA);

  return { inicio, fin };
}

// Identificador estable, idéntico al del cliente Dart: la fecha del lunes
// en horario de Bolivia (`AAAA-MM-DD`).
export function identificadorPeriodo(inicio) {
  const local = new Date(
    inicio.getTime() - OFFSET_BOLIVIA_HORAS * MILISEGUNDOS_HORA,
  );
  const anio = local.getUTCFullYear();
  const mes = String(local.getUTCMonth() + 1).padStart(2, "0");
  const dia = String(local.getUTCDate()).padStart(2, "0");
  return `${anio}-${mes}-${dia}`;
}

function dentroDelPeriodo(fechaTexto, periodo) {
  if (!fechaTexto) return false;
  const fecha = new Date(fechaTexto);
  if (Number.isNaN(fecha.getTime())) return false;
  return fecha >= periodo.inicio && fecha < periodo.fin;
}

// Una cuenta es pública salvo que `preferencias.privacidad.perfilPublico`
// sea explícitamente false.
function cuentaPublicaDeUsuario(datosUsuario) {
  const privacidad = datosUsuario?.preferencias?.privacidad;
  return privacidad?.perfilPublico !== false;
}

export async function generarTopSemanal(env) {
  try {
    const { token, proyecto } = await obtenerToken(env);

    const periodo = periodoQueCierra();
    const idPeriodo = identificadorPeriodo(periodo.inicio);

    // No se regenera un resultado ya publicado: los resultados de una semana
    // cerrada nunca deben cambiar ni duplicarse.
    if (await existeDocumento(token, proyecto, "topSemanal", idPeriodo)) {
      console.log(`El Top ${idPeriodo} ya existe; no se regenera.`);
      return { id: idPeriodo, generado: false };
    }

    const [meGusta, comentarios, publicaciones, usuarios] = await Promise.all([
      listarColeccion(token, proyecto, "meGusta"),
      listarColeccion(token, proyecto, "comentarios"),
      listarColeccion(token, proyecto, "publicaciones"),
      listarColeccion(token, proyecto, "usuarios"),
    ]);

    // La cuenta de servicio puede leer `usuarios`, así que se usa como fuente
    // autoritativa de la privacidad actual, además del valor copiado en cada
    // publicación. Así se respeta el cambio aunque la publicación sea antigua.
    const privacidadUsuarios = {};
    for (const usuario of usuarios) {
      privacidadUsuarios[usuario.id] = cuentaPublicaDeUsuario(usuario);
    }

    const mapaPublicaciones = {};
    for (const publicacion of publicaciones) {
      if (publicacion.estadoModeracion !== "aprobado") continue;
      if (publicacion.mostrarEnTop === false) continue;
      if (publicacion.cuentaPublica === false) continue;
      // Solo entran cuentas conocidas y públicas: si no se puede confirmar la
      // privacidad, se excluye (nunca se asume pública).
      if (privacidadUsuarios[publicacion.uidAutor] !== true) continue;
      mapaPublicaciones[publicacion.id] = publicacion;
    }

    const conteoMeGusta = {};
    for (const item of meGusta) {
      if (!item.publicacionId) continue;
      if (!dentroDelPeriodo(item.fecha, periodo)) continue;
      conteoMeGusta[item.publicacionId] =
        (conteoMeGusta[item.publicacionId] || 0) + 1;
    }

    const conteoComentarios = {};
    for (const item of comentarios) {
      if (!item.publicacionId) continue;
      if (item.estadoModeracion !== "aprobado") continue;
      if (!dentroDelPeriodo(item.fecha, periodo)) continue;
      conteoComentarios[item.publicacionId] =
        (conteoComentarios[item.publicacionId] || 0) + 1;
    }

    const armar = (conteo, clave) => {
      return Object.entries(conteo)
        .map(([id, total]) => {
          const publicacion = mapaPublicaciones[id];
          if (!publicacion) return null;

          return {
            id,
            nombreAutor: publicacion.nombreAutor || "Usuario Lulilu",
            texto: publicacion.texto || "",
            mediaUrl: publicacion.mediaUrl || "",
            meGusta: conteoMeGusta[id] || 0,
            comentarios: conteoComentarios[id] || 0,
            [clave]: total,
          };
        })
        .filter((item) => item !== null)
        .sort((a, b) => b[clave] - a[clave])
        .slice(0, MAXIMO_RESULTADOS);
    };

    const topMeGusta = armar(conteoMeGusta, "meGusta");
    const topComentarios = armar(conteoComentarios, "comentarios");

    await escribirDocumento(token, proyecto, "topSemanal", idPeriodo, {
      semana: idPeriodo,
      inicio: periodo.inicio,
      fin: periodo.fin,
      generadoEn: new Date(),
      topMeGusta,
      topComentarios,
    });

    console.log(
      `Top de la semana ${idPeriodo} generado: ` +
        `${topMeGusta.length} por Me gusta, ${topComentarios.length} por comentarios.`,
    );

    return { id: idPeriodo, generado: true };
  } catch (error) {
    console.error("Error al generar el Top de la semana:", error);
    throw error;
  }
}
