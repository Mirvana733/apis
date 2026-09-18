export default {
	async fetch(request, env) {
		if (request.method !== "POST") {
			return new Response("Método no permitido", { status: 405 });
		}

		try {
			const data = await request.json();

			const { destinatario, nombreDestinatario, asunto, html } = data;

			if (!destinatario || !asunto || !html) {
				return new Response(
					JSON.stringify({
						error: "Faltan datos obligatorios.",
					}),
					{
						status: 400,
						headers: {
							"Content-Type": "application/json",
						},
					},
				);
			}

			const respuesta = await fetch(
				"https://api.brevo.com/v3/smtp/email",
				{
					method: "POST",
					headers: {
						accept: "application/json",
						"api-key": env.BREVO_API_KEY,
						"content-type": "application/json",
					},
					body: JSON.stringify({
						sender: {
							name: "Lulilu",
							email: "zambranarojasluzmirvana@gmail.com",
						},
						to: [
							{
								email: destinatario,
								name: nombreDestinatario || undefined,
							},
						],
						subject: asunto,
						htmlContent: html,
					}),
				},
			);

			const resultado = await respuesta.text();

			if (!respuesta.ok) {
				return new Response(
					JSON.stringify({
						error: "Brevo rechazó el envío.",
						detalle: resultado,
					}),
					{
						status: respuesta.status,
						headers: {
							"Content-Type": "application/json",
						},
					},
				);
			}

			return new Response(
				JSON.stringify({
					exito: true,
					mensaje: "Correo enviado correctamente.",
					brevo: resultado,
				}),
				{
					status: 200,
					headers: {
						"Content-Type": "application/json",
					},
				},
			);
		} catch (error) {
			return new Response(
				JSON.stringify({
					error: "Error al procesar la solicitud.",
					detalle: error.message,
				}),
				{
					status: 500,
					headers: {
						"Content-Type": "application/json",
					},
				},
			);
		}
	},
};