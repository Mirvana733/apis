const {https, setGlobalOptions} = require("firebase-functions");
const {onRequest, onCall} = require("firebase-functions/https");
const {onObjectFinalized} = require("firebase-functions/v2/storage");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp, FieldValue} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {getAuth} = require("firebase-admin/auth");
const {
  RekognitionClient,
  DetectModerationLabelsCommand,
  StartContentModerationCommand,
  GetContentModerationCommand,
  CompareFacesCommand,
} = require("@aws-sdk/client-rekognition");
const {
  TextractClient,
  DetectDocumentTextCommand,
} = require("@aws-sdk/client-textract");
const {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
} = require("@aws-sdk/client-s3");
const brevo = require("@getbrevo/brevo");

setGlobalOptions({maxInstances: 10});

initializeApp();
const db = getFirestore();

const geminiApiKey = defineSecret("GEMINI_API_KEY");
const brevoApiKey = defineSecret("BREVO_API_KEY");
const openaiApiKey = defineSecret("OPENAI_API_KEY");
const awsAccessKeyId = defineSecret("AWS_ACCESS_KEY_ID");
const awsSecretAccessKey = defineSecret("AWS_SECRET_ACCESS_KEY");
const awsRegion = defineSecret("AWS_REGION");
const awsS3Bucket = defineSecret("AWS_S3_BUCKET");
const proveedorImagenes = defineSecret("PROVEEDOR_IMAGENES");
const proveedorKyc = defineSecret("PROVEEDOR_KYC");

exports.publicarComentario = onCall({secrets: [geminiApiKey]}, async (request) => {
  if (!request.auth) {
    throw new https.HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const texto = request.data.texto;

  if (typeof texto !== "string" || texto.trim().length === 0) {
    throw new https.HttpsError("invalid-argument", "Escribe un comentario.");
  }

  if (texto.length > 500) {
    throw new https.HttpsError(
      "invalid-argument",
      "El comentario es demasiado largo.",
    );
  }

  const publicacionId =
    typeof request.data.publicacionId === "string"
      ? request.data.publicacionId.trim()
      : "";

  const autorDoc = await db.collection("usuarios").doc(request.auth.uid).get();
  const datosAutor = autorDoc.exists ? autorDoc.data() : {};
  const nombreAutor =
    [datosAutor.nombre, datosAutor.apellidoPaterno]
      .filter(Boolean)
      .join(" ")
      .trim() || "Usuario Lulilu";

  const prompt = `
Analiza el siguiente comentario para una red social.

Determina si contiene:
- insultos o lenguaje ofensivo
- amenazas
- contenido sexual inapropiado
- discurso de odio
- acoso
- contenido peligroso

Responde únicamente JSON con este formato:
{"aprobado": true, "motivo": ""}
o
{"aprobado": false, "motivo": "razón breve"}

Sin texto adicional.

Comentario:
${texto}
`;

  try {
    const respuesta = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": geminiApiKey.value(),
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [{text: prompt}],
            },
          ],
          generationConfig: {
            responseMimeType: "application/json",
          },
        }),
      }
    );

    if (!respuesta.ok) {
      const cuerpo = await respuesta.text();
      throw new Error(`Gemini ${respuesta.status}: ${cuerpo}`);
    }

    const data = await respuesta.json();
    const textoRespuesta = String(
      data.candidates[0].content.parts[0].text,
    )
      .replace(/```json|```/g, "")
      .trim();

    let aprobado = false;
    let motivo = "";

    try {
      const parse = JSON.parse(textoRespuesta);
      aprobado = parse.aprobado === true;
      motivo =
        typeof parse.motivo === "string"
          ? String(parse.motivo).trim()
          : "";
    } catch (error) {
      const enTexto = textoRespuesta.toUpperCase();
      aprobado =
        !enTexto.includes("BLOQUEADO") &&
        enTexto.includes("APROBADO");
    }

    if (!aprobado) {
      return {
        aprobado: false,
        motivo: motivo || "Contenido inapropiado",
        id: null,
      };
    }

    const referencia = await db.collection("comentarios").add({
      uidUsuario: request.auth.uid,
      publicacionId: publicacionId || null,
      nombreAutor,
      texto,
      estadoModeracion: "aprobado",
      fecha: FieldValue.serverTimestamp(),
    });

    return {
      aprobado: true,
      motivo: null,
      id: referencia.id,
    };
  } catch (error) {
    console.error(error);
    throw new https.HttpsError(
      "internal",
      "No se pudo analizar el comentario.",
    );
  }
});

function normalizarNumeroCI(valor) {
  return String(valor || "").replace(/\D/g, "");
}

function numeroEscritoCoincide(textoOCR, numeroIngresado) {
  const numeroOCR = normalizarNumeroCI(textoOCR);
  const numeroUsuario = normalizarNumeroCI(numeroIngresado);

  if (numeroOCR.length < 6 || numeroUsuario.length < 6) {
    return false;
  }

  return (
    numeroOCR === numeroUsuario ||
    numeroOCR.includes(numeroUsuario) ||
    numeroUsuario.includes(numeroOCR)
  );
}

async function verificarConGemini(ciBytes, selfieBytes, numero, mimeCI, mimeSelfie) {
  const prompt = `
Tienes dos imágenes:

1. Selfie: una foto del rostro de una persona.
2. Documento: el anverso de una cédula de identidad.

Realiza lo siguiente:
- Extrae el número de cédula que aparece en el documento (solo dígitos).
- Determina si la persona de la selfie es la misma persona del rostro que aparece en la foto del documento.

Responde únicamente JSON con este formato:
{
  "numeroCI": "1234567",
  "carasCoinciden": true
}

Sin texto adicional.
`;

  const respuesta = await fetch(
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": geminiApiKey.value(),
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {text: prompt},
              {inline_data: {mime_type: mimeSelfie, data: selfieBytes.toString("base64")}},
              {inline_data: {mime_type: mimeCI || mimeSelfie, data: ciBytes.toString("base64")}},
            ],
          },
        ],
        generationConfig: {
          responseMimeType: "application/json",
        },
      }),
    },
  );

  if (!respuesta.ok) {
    const cuerpo = await respuesta.text();
    throw new Error(`Gemini KYC ${respuesta.status}: ${cuerpo}`);
  }

  const data = await respuesta.json();
  const texto = String(data.candidates[0].content.parts[0].text)
    .replace(/```json|```/g, "")
    .trim();

  let parse;
  try {
    parse = JSON.parse(texto);
  } catch (error) {
    throw new Error(`Gemini KYC no devolvió JSON válido: ${texto}`);
  }

  const numeroValido = numeroEscritoCoincide(
    String(parse.numeroCI || ""),
    numero,
  );
  const carasCoinciden = parse.carasCoinciden === true;

  return {
    numeroValido,
    carasCoinciden,
    aprobado: numeroValido && carasCoinciden,
  };
}

async function verificarConAws(ciBytes, selfieBytes, numero) {
  if (!awsAccessKeyId.value() || !awsSecretAccessKey.value()) {
    throw new Error("Faltan credenciales AWS.");
  }

  const region = awsRegion.value() || "us-east-1";
  const credenciales = {
    accessKeyId: awsAccessKeyId.value(),
    secretAccessKey: awsSecretAccessKey.value(),
  };

  const textract = new TextractClient({
    region,
    credentials: credenciales,
  });

  const deteccion = await textract.send(
    new DetectDocumentTextCommand({
      Document: {Bytes: ciBytes},
    }),
  );

  const lineas = (deteccion.Blocks || [])
    .filter((bloque) => bloque.BlockType === "LINE")
    .map((bloque) => bloque.Text || "");

  const numeroValido = numeroEscritoCoincide(lineas.join(" "), numero);

  const comparacion = await crearClienteRekognition().send(
    new CompareFacesCommand({
      SourceImage: {Bytes: selfieBytes},
      TargetImage: {Bytes: ciBytes},
      SimilarityThreshold: 75,
    }),
  );

  const coincidencias = comparacion.FaceMatches || [];
  const carasCoinciden =
    coincidencias.length > 0 && coincidencias[0].Similarity >= 75;

  return {
    numeroValido,
    carasCoinciden,
    aprobado: numeroValido && carasCoinciden,
  };
}

exports.verificarIdentidad = onCall(
  {
    secrets: [geminiApiKey, awsAccessKeyId, awsSecretAccessKey, awsRegion, proveedorKyc],
  },
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const uid = request.auth.uid;

    const datosEsperados = [
      "nombre",
      "apellidoPaterno",
      "apellidoMaterno",
      "fechaNacimiento",
      "numero",
    ];

    for (const campo of datosEsperados) {
      if (
        request.data[campo] === undefined ||
        request.data[campo] === null ||
        String(request.data[campo]).trim().length === 0
      ) {
        throw new https.HttpsError(
          "invalid-argument",
          `Falta el campo ${campo}.`,
        );
      }
    }

    if (
      typeof request.data.fotoCI !== "string" ||
      !request.data.fotoCI.startsWith(`usuarios/${uid}/`)
    ) {
      throw new https.HttpsError(
        "invalid-argument",
        "La foto de la CI no es válida.",
      );
    }

    if (
      typeof request.data.selfie !== "string" ||
      !request.data.selfie.startsWith(`usuarios/${uid}/`)
    ) {
      throw new https.HttpsError(
        "invalid-argument",
        "La selfie no es válida.",
      );
    }

    const bucket = getStorage().bucket();
    const archivoCI = bucket.file(request.data.fotoCI);
    const archivoSelfie = bucket.file(request.data.selfie);

    let ciBytes;
    let selfieBytes;
    try {
      const [ci] = await archivoCI.download();
      const [selfie] = await archivoSelfie.download();
      ciBytes = ci;
      selfieBytes = selfie;
    } catch (error) {
      console.error("No se pudieron leer las imágenes de identidad:", error);
      throw new https.HttpsError(
        "failed-precondition",
        "No se pudieron leer las imágenes subidas.",
      );
    }

    const mimeDe = (ruta) =>
      ruta.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";

    const proveedor = (proveedorKyc.value() || "gemini").toLowerCase();
    const numero = String(request.data.numero);

    let resultado;
    try {
      resultado =
        proveedor === "aws"
          ? await verificarConAws(ciBytes, selfieBytes, numero)
          : await verificarConGemini(
              ciBytes,
              selfieBytes,
              numero,
              mimeDe(request.data.fotoCI),
              mimeDe(request.data.selfie),
            );
    } catch (error) {
      console.error("Error en verificación de identidad:", error);
      throw new https.HttpsError(
        "internal",
        proveedor === "aws"
          ? "La verificación de identidad no está configurada (faltan credenciales AWS)."
          : "No se pudo completar la verificación de identidad.",
      );
    }

    const doc = db.collection("usuarios").doc(uid);

    if (resultado.aprobado) {
      await doc.update({
        estadoVerificacion: "verificado",
        verificacionIdentidad: true,
        fechaVerificacion: FieldValue.serverTimestamp(),
        resultadoVerificacion: {
          aprobado: true,
          numeroValido: resultado.numeroValido,
          carasCoinciden: resultado.carasCoinciden,
          proveedor,
        },
      });
    } else {
      await doc.update({
        estadoVerificacion: "rechazado",
        verificacionIdentidad: false,
        resultadoVerificacion: {
          aprobado: false,
          numeroValido: resultado.numeroValido,
          carasCoinciden: resultado.carasCoinciden,
          proveedor,
        },
      });
    }

    await archivoCI.delete().catch(() => {});

    return {
      aprobado: resultado.aprobado,
      numeroValido: resultado.numeroValido,
      carasCoinciden: resultado.carasCoinciden,
    };
  },
);

exports.crearPublicacion = onCall(async (request) => {
  if (!request.auth) {
    throw new https.HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const tipo = request.data.tipo;
  const texto = typeof request.data.texto === "string" ? request.data.texto.trim() : "";
  const mediaUrl = typeof request.data.mediaUrl === "string" ? request.data.mediaUrl : "";

  if (!["texto", "imagen", "video", "audio"].includes(tipo)) {
    throw new https.HttpsError(
      "invalid-argument",
      "El tipo de publicación debe ser texto, imagen, video o audio.",
    );
  }

  if (tipo === "texto" && texto.length === 0) {
    throw new https.HttpsError(
      "invalid-argument",
      "Una publicación de texto debe tener contenido.",
    );
  }

  const expiraEn = new Timestamp(
    Math.floor(Date.now() / 1000) + 24 * 60 * 60,
    0,
  );

  const autorDoc = await db.collection("usuarios").doc(request.auth.uid).get();
  const datosAutor = autorDoc.exists ? autorDoc.data() : {};
  const nombreAutor =
    [datosAutor.nombre, datosAutor.apellidoPaterno]
      .filter(Boolean)
      .join(" ")
      .trim() || "Usuario Lulilu";

  const referencia = await db.collection("publicaciones").add({
    uidAutor: request.auth.uid,
    nombreAutor,
    tipo,
    texto,
    mediaUrl,
    estadoModeracion: "en_revision",
    resultadoModeracion: null,
    fecha: FieldValue.serverTimestamp(),
    expiraEn,
  });

  return {
    id: referencia.id,
    estadoModeracion: "en_revision",
  };
});

const PROMPT_TEXTO = `
Analiza la siguiente publicación de texto para una red social.

Determina si contiene:
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

Publicación:
`;

exports.moderarTextoPublicacion = onCall(
  {secrets: [geminiApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const texto = String(request.data.texto || "").trim();

    if (texto.length === 0) {
      throw new https.HttpsError(
        "invalid-argument",
        "Escribe una publicación.",
      );
    }

    if (texto.length > 1000) {
      throw new https.HttpsError(
        "invalid-argument",
        "El texto es demasiado largo.",
      );
    }

    try {
      const respuesta = await fetch(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": geminiApiKey.value(),
          },
          body: JSON.stringify({
            contents: [
              {
                parts: [{text: `${PROMPT_TEXTO}\n${texto}`}],
              },
            ],
            generationConfig: {
              responseMimeType: "application/json",
            },
          }),
        }
      );

      if (!respuesta.ok) {
        const cuerpo = await respuesta.text();
        throw new Error(`Gemini ${respuesta.status}: ${cuerpo}`);
      }

      const data = await respuesta.json();
      const textoRespuesta = String(
        data.candidates[0].content.parts[0].text,
      )
        .replace(/```json|```/g, "")
        .trim();

      let aprobado = false;
      let motivo = "";

      try {
        const parse = JSON.parse(textoRespuesta);
        aprobado = parse.aprobado === true;
        motivo =
          typeof parse.motivo === "string"
            ? String(parse.motivo).trim()
            : "";
      } catch (error) {
        const enTexto = textoRespuesta.toUpperCase();
        aprobado =
          !enTexto.includes("BLOQUEADO") &&
          enTexto.includes("APROBADO");
      }

      if (!aprobado) {
        return {
          aprobado: false,
          motivo: motivo || "Contenido inapropiado",
          id: null,
        };
      }

      const autorDoc = await db
        .collection("usuarios")
        .doc(request.auth.uid)
        .get();
      const datosAutor = autorDoc.exists ? autorDoc.data() : {};
      const nombreAutor =
        [datosAutor.nombre, datosAutor.apellidoPaterno]
          .filter(Boolean)
          .join(" ")
          .trim() || "Usuario Lulilu";

      const referencia = await db.collection("publicaciones").add({
        uidAutor: request.auth.uid,
        nombreAutor,
        tipo: "texto",
        texto,
        mediaUrl: "",
        estadoModeracion: "aprobado",
        resultadoModeracion: {proveedor: "gemini"},
        fecha: FieldValue.serverTimestamp(),
      });

      return {
        aprobado: true,
        motivo: null,
        id: referencia.id,
      };
    } catch (error) {
      console.error("Error al moderar texto:", error);
      throw new https.HttpsError(
        "internal",
        "No se pudo analizar el texto.",
      );
    }
  },
);

const CONFIANZA_MIN_IMAGEN = 60;
const MAX_BYTES_IMAGEN = 5 * 1024 * 1024;

const PROMPT_IMAGEN = `
Analiza esta imagen para una red social.

Determina si contiene:
- desnudez o contenido sexual inapropiado
- violencia, sangre o armas
- símbolos de odio o racistas
- contenido peligroso o extremista

Ignora contenido inofensivo como dibujos, memes o personajes de ficción.

Responde solamente con:
APROBADO
o
BLOQUEADO
`;

async function marcarPublicacion(idPublicacion, cambios) {
  const datosCambio = {
    ...cambios,
    expiraEn: FieldValue.delete(),
  };

  try {
    await db.collection("publicaciones").doc(idPublicacion).update(datosCambio);
  } catch (error) {
    console.error(`No se pudo actualizar la publicación ${idPublicacion}:`, error);
  }
}

function crearClienteRekognition() {
  return new RekognitionClient({
    region: awsRegion.value() || "us-east-1",
    credentials: {
      accessKeyId: awsAccessKeyId.value(),
      secretAccessKey: awsSecretAccessKey.value(),
    },
  });
}

async function analizarImagenConRekognition(bytes) {
  if (!awsAccessKeyId.value() || !awsSecretAccessKey.value()) {
    throw new Error("Faltan credenciales AWS.");
  }

  const resultado = await crearClienteRekognition().send(
    new DetectModerationLabelsCommand({
      Image: {Bytes: bytes},
      MinConfidence: CONFIANZA_MIN_IMAGEN,
    })
  );

  return (resultado.ModerationLabels || []).map((etiqueta) => ({
    nombre: etiqueta.Name,
    categoria: etiqueta.ParentName || null,
    confianza: etiqueta.Confidence,
  }));
}

async function analizarImagenConGemini(bytes, mimeType) {
  const respuesta = await fetch(
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": geminiApiKey.value(),
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {text: PROMPT_IMAGEN},
              {
                inline_data: {
                  mime_type: mimeType,
                  data: bytes.toString("base64"),
                },
              },
            ],
          },
        ],
      }),
    }
  );

  if (!respuesta.ok) {
    const cuerpo = await respuesta.text();
    throw new Error(`Gemini ${respuesta.status}: ${cuerpo}`);
  }

  const data = await respuesta.json();
  const texto = String(data.candidates[0].content.parts[0].text)
    .trim()
    .toUpperCase();

  if (texto.includes("BLOQUEADO")) {
    return [{nombre: "contenido_inapropiado", categoria: null, confianza: 1}];
  }

  return [];
}

exports.moderarImagenPublicacion = onObjectFinalized(
  {
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: [geminiApiKey, awsAccessKeyId, awsSecretAccessKey, awsRegion, proveedorImagenes],
  },
  async (event) => {
    const ruta = event.data.name;
    const nombreBucket = event.data.bucket;

    if (!ruta.startsWith("publicaciones/")) {
      return;
    }

    const partes = ruta.split("/");
    if (partes.length < 3) {
      return;
    }

    const idPublicacion = partes[partes.length - 1].split(".")[0];
    const contentType = event.data.contentType || "";

    if (!["image/jpeg", "image/png"].includes(contentType)) {
      await marcarPublicacion(idPublicacion, {
        estadoModeracion: "rechazado",
        motivo: "Formato de imagen no permitido.",
      });
      await getStorage().bucket(nombreBucket).file(ruta).delete().catch(() => {});
      return;
    }

    const archivo = getStorage().bucket(nombreBucket).file(ruta);
    const [bytes] = await archivo.download();

    if (bytes.length > MAX_BYTES_IMAGEN) {
      await marcarPublicacion(idPublicacion, {
        estadoModeracion: "rechazado",
        motivo: "La imagen supera el tamaño máximo permitido.",
      });
      await archivo.delete().catch(() => {});
      return;
    }

    const proveedor = (proveedorImagenes.value() || "gemini").toLowerCase();

    let etiquetas;
    try {
      etiquetas =
        proveedor === "aws"
          ? await analizarImagenConRekognition(bytes)
          : await analizarImagenConGemini(bytes, contentType);
    } catch (error) {
      console.error("Error al moderar imagen:", error);

      await marcarPublicacion(idPublicacion, {
        estadoModeracion: "rechazado",
        motivo:
          proveedor === "aws"
            ? "La moderación de imágenes no está configurada (faltan credenciales AWS)."
            : "No se pudo analizar la imagen.",
      });
      return;
    }

    if (etiquetas.length > 0) {
      await marcarPublicacion(idPublicacion, {
        estadoModeracion: "bloqueado",
        motivo: "Contenido inapropiado en la imagen.",
        resultadoModeracion: {etiquetas, proveedor},
      });
      await archivo.delete().catch(() => {});
      return;
    }

    await marcarPublicacion(idPublicacion, {
      estadoModeracion: "aprobado",
      mediaUrl: ruta,
      resultadoModeracion: {etiquetas, proveedor},
    });
  }
);

const CONFIANZA_MIN_VIDEO = 50;
const MAX_BYTES_VIDEO = 80 * 1024 * 1024;
const MAX_BYTES_AUDIO = 25 * 1024 * 1024;
const TIPOS_VIDEO = ["video/mp4", "video/quicktime"];
const TIPOS_AUDIO = [
  "audio/mpeg",
  "audio/mp4",
  "audio/ogg",
  "audio/wav",
  "audio/webm",
];

async function esperarModeracionVideo(rekognition, jobId, maxIntentos = 90) {
  for (let intento = 0; intento < maxIntentos; intento++) {
    await new Promise((resolver) => setTimeout(resolver, 6000));

    let resultado;
    try {
      resultado = await rekognition.send(
        new GetContentModerationCommand({JobId: jobId}),
      );
    } catch (error) {
      if (error?.name === "ProvisionedThroughputExceededException") {
        continue;
      }
      throw error;
    }

    if (resultado?.JobStatus === "SUCCEEDED") {
      return resultado;
    }

    if (resultado?.JobStatus === "FAILED") {
      throw new Error(
        `Rekognition Video falló: ${resultado?.StatusMessage || "sin detalle"}`,
      );
    }
  }

  throw new Error("Se agotó el tiempo de espera para Rekognition Video.");
}

async function subirVideoAS3(ruta, bytes) {
  if (!awsS3Bucket.value()) {
    throw new Error("Falta el bucket AWS_S3_BUCKET.");
  }

  if (!awsAccessKeyId.value() || !awsSecretAccessKey.value()) {
    throw new Error("Faltan credenciales AWS.");
  }

  const s3 = new S3Client({
    region: awsRegion.value() || "us-east-1",
    credentials: {
      accessKeyId: awsAccessKeyId.value(),
      secretAccessKey: awsSecretAccessKey.value(),
    },
  });

  await s3.send(
    new PutObjectCommand({
      Bucket: awsS3Bucket.value(),
      Key: ruta,
      Body: bytes,
      ContentType: "video/mp4",
    }),
  );

  return s3;
}

exports.moderarVideoPublicacion = onObjectFinalized(
  {
    timeoutSeconds: 540,
    memory: "2GiB",
    secrets: [awsAccessKeyId, awsSecretAccessKey, awsRegion, awsS3Bucket],
  },
  async (event) => {
    const ruta = event.data.name;
    const nombreBucket = event.data.bucket;

    if (!ruta.startsWith("publicaciones/")) {
      return;
    }

    const partes = ruta.split("/");
    if (partes.length < 3) {
      return;
    }

    const idPublicacion = partes[partes.length - 1].split(".")[0];
    const contentType = event.data.contentType || "";

    if (!TIPOS_VIDEO.includes(contentType)) {
      await marcarPublicacion(idPublicacion, {
        estadoModeracion: "rechazado",
        motivo: "Formato de video no permitido.",
      });
      await getStorage().bucket(nombreBucket).file(ruta).delete().catch(() => {});
      return;
    }

    const archivo = getStorage().bucket(nombreBucket).file(ruta);
    const [bytes] = await archivo.download();

    if (bytes.length > MAX_BYTES_VIDEO) {
      await marcarPublicacion(idPublicacion, {
        estadoModeracion: "rechazado",
        motivo: "El video supera el tamaño máximo permitido.",
      });
      await archivo.delete().catch(() => {});
      return;
    }

    let s3;
    try {
      s3 = await subirVideoAS3(ruta, bytes);
    } catch (error) {
      console.error("No se pudo subir el video a S3:", error);
      await marcarPublicacion(idPublicacion, {
        estadoModeracion: "rechazado",
        motivo:
          "La moderación de videos no está configurada (faltan credenciales AWS o bucket S3).",
      });
      return;
    }

    try {
      const rekognition = crearClienteRekognition();
      const inicio = await rekognition.send(
        new StartContentModerationCommand({
          Video: {
            S3Object: {
              Bucket: awsS3Bucket.value(),
              Name: ruta,
            },
          },
          MinConfidence: CONFIANZA_MIN_VIDEO,
        }),
      );

      const resultado = await esperarModeracionVideo(
        rekognition,
        inicio.JobId,
      );

      const etiquetas = new Map();
      for (const item of resultado?.ModerationLabels || []) {
        const etiqueta = item.ModerationLabel;
        if (!etiqueta || etiqueta.Confidence < CONFIANZA_MIN_VIDEO) {
          continue;
        }
        if (!etiquetas.has(etiqueta.Name)) {
          etiquetas.set(etiqueta.Name, {
            nombre: etiqueta.Name,
            categoria: etiqueta.ParentName || null,
            confianza: etiqueta.Confidence,
            frames: 0,
          });
        }
        etiquetas.get(etiqueta.Name).frames++;
      }

      const listaEtiquetas = [...etiquetas.values()];

      if (listaEtiquetas.length > 0) {
        await marcarPublicacion(idPublicacion, {
          estadoModeracion: "bloqueado",
          motivo: "Contenido inapropiado en el video.",
          resultadoModeracion: {
            etiquetas: listaEtiquetas,
            proveedor: "aws-rekognition-video",
          },
        });
        await archivo.delete().catch(() => {});
      } else {
        await marcarPublicacion(idPublicacion, {
          estadoModeracion: "aprobado",
          mediaUrl: ruta,
          resultadoModeracion: {
            etiquetas: [],
            proveedor: "aws-rekognition-video",
          },
        });
      }
    } catch (error) {
      console.error("Error al moderar video:", error);

      try {
        await s3.send(
          new DeleteObjectCommand({
            Bucket: awsS3Bucket.value(),
            Key: ruta,
          }),
        );
      } catch (errorEliminar) {
        console.error("No se pudo eliminar el objeto de S3:", errorEliminar);
      }

      await marcarPublicacion(idPublicacion, {
        estadoModeracion: "rechazado",
        motivo: "No se pudo analizar el video.",
      });
    }
  },
);

async function transcribirYModerarAudio(bytes, contentType) {
  if (!openaiApiKey.value()) {
    throw new Error("Falta OPENAI_API_KEY.");
  }

  const form = new FormData();
  form.append("model", "gpt-transcribe");
  form.append("response_format", "json");
  form.append(
    "file",
    new Blob([bytes], {type: contentType || "audio/mpeg"}),
    "audio",
  );

  const respuesta = await fetch(
    "https://api.openai.com/v1/audio/transcriptions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiApiKey.value()}`,
      },
      body: form,
    },
  );

  if (!respuesta.ok) {
    const cuerpo = await respuesta.text();
    throw new Error(`OpenAI transcripción ${respuesta.status}: ${cuerpo}`);
  }

  const data = await respuesta.json();
  const texto = String(data.text || "").trim();

  if (texto.length === 0) {
    return {transcripcion: texto, aprobado: true};
  }

  const moderacion = await fetch("https://api.openai.com/v1/moderations", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${openaiApiKey.value()}`,
    },
    body: JSON.stringify({
      model: "omni-moderation-latest",
      input: texto,
    }),
  });

  if (!moderacion.ok) {
    const cuerpo = await moderacion.text();
    throw new Error(`OpenAI moderación ${moderacion.status}: ${cuerpo}`);
  }

  const datosModeracion = await moderacion.json();
  const flagged = datosModeracion.results[0].flagged;

  return {transcripcion: texto, aprobado: !flagged};
}

exports.moderarAudioPublicacion = onObjectFinalized(
  {
    timeoutSeconds: 300,
    memory: "1GiB",
    secrets: [openaiApiKey],
  },
  async (event) => {
    const ruta = event.data.name;
    const nombreBucket = event.data.bucket;

    if (!ruta.startsWith("publicaciones/")) {
      return;
    }

    const partes = ruta.split("/");
    if (partes.length < 3) {
      return;
    }

    const idPublicacion = partes[partes.length - 1].split(".")[0];
    const contentType = event.data.contentType || "";

    if (!TIPOS_AUDIO.includes(contentType)) {
      await marcarPublicacion(idPublicacion, {
        estadoModeracion: "rechazado",
        motivo: "Formato de audio no permitido.",
      });
      await getStorage().bucket(nombreBucket).file(ruta).delete().catch(() => {});
      return;
    }

    const archivo = getStorage().bucket(nombreBucket).file(ruta);
    const [bytes] = await archivo.download();

    if (bytes.length > MAX_BYTES_AUDIO) {
      await marcarPublicacion(idPublicacion, {
        estadoModeracion: "rechazado",
        motivo: "El audio supera el tamaño máximo permitido.",
      });
      await archivo.delete().catch(() => {});
      return;
    }

    try {
      const {transcripcion, aprobado} =
        await transcribirYModerarAudio(bytes, contentType);

      if (!aprobado) {
        await marcarPublicacion(idPublicacion, {
          estadoModeracion: "bloqueado",
          motivo: "Contenido inapropiado en el audio.",
          transcripcion,
          resultadoModeracion: {proveedor: "openai-gpt-transcribe"},
        });
        await archivo.delete().catch(() => {});
      } else {
        await marcarPublicacion(idPublicacion, {
          estadoModeracion: "aprobado",
          mediaUrl: ruta,
          transcripcion,
          resultadoModeracion: {proveedor: "openai-gpt-transcribe"},
        });
      }
    } catch (error) {
      console.error("Error al moderar audio:", error);
      await marcarPublicacion(idPublicacion, {
        estadoModeracion: "rechazado",
        motivo: "La moderación de audio no está configurada (falta OPENAI_API_KEY) o no se pudo analizar.",
      });
    }
  },
);

function escaparHtml(valor) {
  return String(valor ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

async function enviarCorreoConBrevo({
  destinatario,
  nombreDestinatario,
  asunto,
  html,
}) {
  if (!brevoApiKey.value()) {
    throw new Error("Falta BREVO_API_KEY.");
  }

  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(destinatario)) {
    throw new Error("El correo del destinatario no es válido.");
  }

  const apiInstance = new brevo.TransactionalEmailsApi();
  apiInstance.setApiKey(
    brevo.TransactionalEmailsApiApiKeys.apiKey,
    brevoApiKey.value(),
  );

  const sendSmtpEmail = new brevo.SendSmtpEmail();
  sendSmtpEmail.subject = asunto;
  sendSmtpEmail.htmlContent = html;
  sendSmtpEmail.sender = {
    name: "Lulilu",
    email: "zambranarojasluzmirvana@gmail.com",
  };
  sendSmtpEmail.to = [
    {
      email: destinatario,
      name: nombreDestinatario || undefined,
    },
  ];

  await apiInstance.sendTransacEmail(sendSmtpEmail);
}

const PLANTILLA_CORREO = (titulo, contenido) => `
  <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; padding: 24px;">
    <div style="background: linear-gradient(135deg, #28C2D1, #39D2C0 45%, #7C6CF0); border-radius: 18px; padding: 26px; text-align: center;">
      <h1 style="color: #ffffff; margin: 0; font-size: 28px;">Lulilu 💗</h1>
    </div>
    <div style="background: #ffffff; border-radius: 0 0 18px 18px; padding: 26px; border: 1px solid #e5e7eb; border-top: none;">
      <h2 style="color: #2d2f33; margin-top: 0;">${titulo}</h2>
      <div style="color: #4b5563; font-size: 15px; line-height: 1.6;">${contenido}</div>
    </div>
    <p style="text-align: center; color: #9ca3af; font-size: 12px;">Este correo fue enviado automáticamente por Lulilu.</p>
  </div>
`;

exports.enviarCorreoBienvenida = onCall(
  {secrets: [brevoApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const uid = request.auth.uid;
    const doc = await db.collection("usuarios").doc(uid).get();
    const datos = doc.exists ? doc.data() : {};

    const correo = String(request.data.correo || datos.correo || "").trim();
    const nombre = String(request.data.nombre || datos.nombre || "").trim();

    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(correo)) {
      throw new https.HttpsError("invalid-argument", "El correo no es válido.");
    }

    try {
      await enviarCorreoConBrevo({
        destinatario: correo,
        nombreDestinatario: nombre,
        asunto: "¡Bienvenido a Lulilu! 💗",
        html: PLANTILLA_CORREO(
          "¡Cuenta creada! 🎉",
          `<p>Hola <strong>${escaparHtml(nombre)}</strong>,</p>
           <p>Se creó una cuenta de <strong>Lulilu</strong> con este correo electrónico.</p>
           <p>Ya puedes iniciar sesión y compartir con la comunidad.</p>`,
        ),
      });
    } catch (error) {
      console.error("Error al enviar correo de bienvenida:", error);
      throw new https.HttpsError(
        "internal",
        "No se pudo enviar el correo de bienvenida.",
      );
    }

    return {enviado: true};
  },
);

exports.notificarNuevoIngreso = onCall(
  {secrets: [brevoApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const uid = request.auth.uid;
    const dispositivo = String(request.data.dispositivo || "").trim();

    const ref = db.collection("usuarios").doc(uid);
    const doc = await ref.get();

    if (!doc.exists) {
      return {notificado: false};
    }

    const datos = doc.data();
    const correo = String(datos.correo || "").trim();
    const nombre =
      [datos.nombre, datos.apellidoPaterno]
        .filter(Boolean)
        .join(" ")
        .trim() || "usuario";

    const dispositivos = Array.isArray(datos.dispositivos)
      ? datos.dispositivos.filter((d) => typeof d === "string")
      : [];

    const esPrimerIngreso = dispositivos.length === 0;
    const esNuevoDispositivo =
      !esPrimerIngreso &&
      dispositivo.length > 0 &&
      !dispositivos.includes(dispositivo);

    let notificado = false;

    if (esNuevoDispositivo) {
      try {
        await enviarCorreoConBrevo({
          destinatario: correo,
          nombreDestinatario: nombre,
          asunto: "Nuevo inicio de sesión en tu cuenta Lulilu",
          html: PLANTILLA_CORREO(
            "Inicio de sesión detectado 🔒",
            `<p>Hola <strong>${escaparHtml(nombre)}</strong>,</p>
             <p>Se inició sesión en tu cuenta de <strong>Lulilu</strong> desde un <strong>dispositivo nuevo</strong>.</p>
             <p><strong>Fecha y hora:</strong> ${new Date().toLocaleString("es-BO")}</p>
             <p>Si fuiste tú, ignora este mensaje. Si no reconoces este acceso, cambia tu contraseña lo antes posible.</p>`,
          ),
        });
        notificado = true;
      } catch (error) {
        console.error("Error al notificar nuevo ingreso:", error);
      }
    }

    const nuevosDispositivos = [...dispositivos];
    if (dispositivo.length > 0 && !nuevosDispositivos.includes(dispositivo)) {
      nuevosDispositivos.push(dispositivo);
      if (nuevosDispositivos.length > 15) {
        nuevosDispositivos.shift();
      }
    }

    await ref.update({
      dispositivos: nuevosDispositivos,
      ultimoIngreso: FieldValue.serverTimestamp(),
    });

    return {notificado};
  },
);

async function borrarDocumentos(coleccion, campo, valor) {
  const consulta = db
    .collection(coleccion)
    .where(campo, "==", valor)
    .orderBy(campo)
    .limit(400);

  const referencias = [];
  let snapshot = await consulta.get();

  while (!snapshot.empty) {
    referencias.push(...snapshot.docs.map((d) => d.ref));
    if (snapshot.docs.length < 400) break;
    const ultimo = snapshot.docs[snapshot.docs.length - 1];
    snapshot = await consulta.startAfter(ultimo).get();
  }

  for (let i = 0; i < referencias.length; i += 400) {
    const lote = db.batch();
    for (const ref of referencias.slice(i, i + 400)) {
      lote.delete(ref);
    }
    await lote.commit();
  }
}

exports.eliminarCuenta = onCall(async (request) => {
  if (!request.auth) {
    throw new https.HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const uid = request.auth.uid;
  const fallos = [];

  try {
    await borrarDocumentos("publicaciones", "uidAutor", uid);
  } catch (error) {
    fallos.push("publicaciones");
  }

  try {
    await borrarDocumentos("comentarios", "uidUsuario", uid);
  } catch (error) {
    fallos.push("comentarios");
  }

  try {
    await db.collection("verificaciones").doc(uid).delete();
  } catch (error) {
    fallos.push("verificaciones");
  }

  try {
    await db.collection("usuarios").doc(uid).delete();
  } catch (error) {
    fallos.push("usuarios");
  }

  const bucket = getStorage().bucket();
  const borradosStorage = [];

  try {
    const [archivos] = await bucket.getFiles({prefix: `usuarios/${uid}/`});
    borradosStorage.push(...archivos.map((a) => a.delete().catch(() => {})));
  } catch (error) {
    fallos.push("storage/usuarios");
  }

  try {
    const [archivos] = await bucket.getFiles({prefix: `publicaciones/${uid}/`});
    borradosStorage.push(...archivos.map((a) => a.delete().catch(() => {})));
  } catch (error) {
    fallos.push("storage/publicaciones");
  }

  await Promise.allSettled(borradosStorage);

  try {
    await getAuth().deleteUser(uid);
  } catch (error) {
    fallos.push("auth");
  }

  return {eliminado: true, fallos};
});

exports.enviarCorreoPrueba = onRequest({secrets: [brevoApiKey]}, async (req, res) => {
  try {
    const apiInstance = new brevo.TransactionalEmailsApi();

    apiInstance.setApiKey(
      brevo.TransactionalEmailsApiApiKeys.apiKey,
      brevoApiKey.value()
    );

    const sendSmtpEmail = new brevo.SendSmtpEmail();

    sendSmtpEmail.subject = "Prueba de Brevo - Lulilu";
    sendSmtpEmail.htmlContent = `
      <h2>¡Hola desde Lulilu! 💗</h2>
      <p>Este es un correo de prueba enviado mediante Brevo.</p>
      <p>La integración de Brevo está funcionando correctamente.</p>
    `;

    sendSmtpEmail.sender = {
      name: "Lulilu",
      email: "zambranarojasluzmirvana@gmail.com",
    };

    sendSmtpEmail.to = [
      {
        email: "zambranarojasluzmirvana@gmail.com",
      },
    ];

    await apiInstance.sendTransacEmail(sendSmtpEmail);

    res.status(200).send("Correo enviado correctamente con Brevo.");
  } catch (error) {
    console.error(error);
    res.status(500).send("Error al enviar el correo con Brevo.");
  }
});