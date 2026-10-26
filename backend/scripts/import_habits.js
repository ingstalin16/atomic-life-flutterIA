
const {
    initializeApp,
    applicationDefault,
} = require("firebase-admin/app");

const {
    getFirestore,
} = require("firebase-admin/firestore");

const templates = require("./habit_templates");

const PROJECT_ID = "atomiclife-habitos";
const APPLY = process.argv.includes("--apply");

// Validar catalogo
function validateTemplates() {
    if (templates.length !== 20) {
        throw new Error(
            `Se esperaban 20 habitos, hay ${templates.length}`
        );
    }

    const ids = new Set();

    for (const habit of templates) {
        if (!habit.id || ids.has(habit.id)) {
            throw new Error(
                `ID invalido o duplicado: ${habit.id}`
            );
        }

        ids.add(habit.id);

        const required = [
            "name",
            "category",
            "identity",
            "context",
            "motivation",
            "microAction",
            "scheduledTime",
        ];

        for (const field of required) {
            if (
                typeof habit[field] !== "string" ||
                habit[field].trim().length === 0
            ) {
                throw new Error(
                    `Campo invalido: ${habit.id}.${field}`
                );
            }
        }

        if (
            !Number.isInteger(habit.durationMinutes) ||
            habit.durationMinutes < 1
        ) {
            throw new Error(
                `Duracion invalida: ${habit.id}`
            );
        }

        if (
            !/^([01]\d|2[0-3]):[0-5]\d$/.test(
                habit.scheduledTime
            )
        ) {
            throw new Error(
                `Horario invalido: ${habit.id}`
            );
        }

        if (
            !Array.isArray(habit.weekDays) ||
            habit.weekDays.length === 0 ||
            habit.weekDays.some(
                (day) => !Number.isInteger(day) ||
                    day < 1 || day > 7
            )
        ) {
            throw new Error(
                `Dias invalidos: ${habit.id}`
            );
        }
    }
}

async function main() {
    validateTemplates();

    console.log(
        `Catalogo validado: ${templates.length} habitos`
    );

    // Simulacion: no modifica Firebase
    if (!APPLY) {
        console.log("Modo simulacion: sin escrituras");

        for (const habit of templates) {
            console.log(`${habit.id} - ${habit.name}`);
        }

        console.log(
            "Para importar ejecuta con --apply"
        );
        return;
    }

    if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
        throw new Error(
            "Falta GOOGLE_APPLICATION_CREDENTIALS"
        );
    }

    initializeApp({
        credential: applicationDefault(),
        projectId: PROJECT_ID,
    });

    const db = getFirestore();
    const collection = db.collection("habit_templates");

    const references = templates.map((habit) =>
        collection.doc(habit.id)
    );

    const existing = await db.getAll(...references);

    const duplicates = existing
        .filter((doc) => doc.exists)
        .map((doc) => doc.id);

    if (duplicates.length > 0) {
        throw new Error(
            "Ya existen estos documentos: " +
            duplicates.join(", ")
        );
    }

    const batch = db.batch();

    for (const habit of templates) {
        const { id, ...data } = habit;

        batch.create(collection.doc(id), {
            ...data,
            isActive: true,
        });
    }

    await batch.commit();

    console.log(
        "20 habitos importados correctamente"
    );
}

main().catch((error) => {
    console.error("Error:", error.message);
    process.exitCode = 1;
});
