
const { initializeApp, cert, deleteApp, getApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const serviceAccount = require('./serviceAccountKey.json');

const app = initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore(app);

const categorias = [
  ['plomeria', 'Plomería', 'Reparación de tuberías, fugas y grifos.', 'plumbing'],
  ['electricidad', 'Electricidad', 'Instalaciones y reparaciones eléctricas.', 'electrical_services'],
  ['carpinteria', 'Carpintería', 'Reparación y fabricación de muebles.', 'carpenter'],
  ['pintura', 'Pintura', 'Pintura de interiores y exteriores.', 'format_paint'],
  ['albanileria', 'Albañilería', 'Construcción y reparación de estructuras.', 'construction'],
  ['cerrajeria', 'Cerrajería', 'Reparación e instalación de cerraduras.', 'lock'],
  ['jardineria', 'Jardinería', 'Mantenimiento y cuidado de jardines.', 'yard'],
  ['limpieza', 'Limpieza', 'Limpieza de hogares y espacios.', 'cleaning_services'],
  ['herreria', 'Herrería', 'Fabricación y reparación de estructuras metálicas.', 'handyman'],
  ['reparaciones', 'Reparaciones generales', 'Otros trabajos y reparaciones del hogar.', 'home_repair_service'],
];

async function cargarCategorias() {
  try {
    let nuevas = 0;

    for (let i = 0; i < categorias.length; i += 500) {
      const lote = db.batch();
      const grupo = categorias.slice(i, i + 500);

      for (const [id, nombre, descripcion, icono] of grupo) {
        const referencia = db.collection('categorias').doc(id);
        const documento = await referencia.get();

        if (!documento.exists) {
          lote.create(referencia, {
            nombre,
            descripcion,
            icono,
            activa: true,
            fechaCreacion: FieldValue.serverTimestamp(),
          });
          nuevas++;
          console.log(`Preparada: ${nombre}`);
        } else {
          console.log(`Ya existe: ${nombre}`);
        }
      }

      if (grupo.length > 0) {
        await lote.commit();
      }
    }

    console.log(`\nCarga terminada. Nuevas categorías: ${nuevas}`);
  } catch (error) {
    console.error('Error al cargar categorías:', error);
    process.exitCode = 1;
  } finally {
    await deleteApp(app);
  }
}

cargarCategorias();
