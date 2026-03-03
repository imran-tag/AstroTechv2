const db = require('../db'); // connexion MySQL2/promise

class DashboardService {

  // static async getDashboardInterventions() {
  //   const sql = `
  //     SELECT
  //       ti.id AS type_id,
  //       ti.categorie,
  //       ti.libelle AS type,
  //       CASE
  //         WHEN LOWER(i.etat) LIKE '%plan%' THEN 'PLANIFIE'
  //         WHEN LOWER(i.etat) LIKE '%cours%' THEN 'EN_COURS'
  //         WHEN LOWER(i.etat) LIKE '%term%'
  //           OR LOWER(i.etat) LIKE '%clos%' THEN 'TERMINE'
  //         ELSE 'AUTRE'
  //       END AS etat,
  //       COUNT(*) AS total
  //     FROM intervention i
  //     JOIN intervention_type ti ON ti.id = i.type_id
  //     WHERE ti.actif = 1
  //     GROUP BY
  //       ti.id,
  //       ti.categorie,
  //       ti.libelle,
  //       etat
  //     ORDER BY
  //       ti.categorie,
  //       ti.libelle;
  //   `;

  //   const [rows] = await db.query(sql);

  //   /**
  //    * Structure retournée :
  //    * {
  //    *   categorie: {
  //    *     type: {
  //    *       type_id,
  //    *       PLANIFIE,
  //    *       EN_COURS,
  //    *       TERMINE
  //    *     }
  //    *   }
  //    * }
  //    */
  //   const dashboard = {};

  //   for (const row of rows) {
  //     const { categorie, type, type_id, etat, total } = row;

  //     if (etat === 'AUTRE') continue;

  //     if (!dashboard[categorie]) {
  //       dashboard[categorie] = {};
  //     }

  //     if (!dashboard[categorie][type]) {
  //       dashboard[categorie][type] = {
  //         type_id,
  //         PLANIFIE: 0,
  //         EN_COURS: 0,
  //         TERMINE: 0
  //       };
  //     }

  //     dashboard[categorie][type][etat] = total;
  //   }

  //   return dashboard;
  // }

  static async getDashboardInterventions() {
    const sql = `
    SELECT
      ti.id AS type_id,
      ti.categorie,
      ti.libelle AS type,
      CASE
        WHEN LOWER(i.etat) LIKE '%term%'
          OR LOWER(i.etat) LIKE '%clos%' THEN 'TERMINE'
        WHEN LOWER(i.etat) LIKE '%cours%' THEN 'EN_COURS'
        WHEN i.date_debut_intervention IS NOT NULL THEN 'PLANIFIE'
        ELSE 'AUTRE'
      END AS etat,
      COUNT(*) AS total
    FROM intervention i
    JOIN intervention_type ti ON ti.id = i.type_id
    WHERE ti.actif = 1
      AND i.archive = 0
    GROUP BY
      ti.id,
      ti.categorie,
      ti.libelle,
      CASE
        WHEN LOWER(i.etat) LIKE '%term%'
          OR LOWER(i.etat) LIKE '%clos%' THEN 'TERMINE'
        WHEN LOWER(i.etat) LIKE '%cours%' THEN 'EN_COURS'
        WHEN i.date_debut_intervention IS NOT NULL THEN 'PLANIFIE'
        ELSE 'AUTRE'
      END
    ORDER BY
      ti.categorie,
      ti.libelle;
  `;

    const [rows] = await db.query(sql);

    const dashboard = {};

    for (const row of rows) {
      const { categorie, type, type_id, etat, total } = row;

      if (etat === 'AUTRE') continue;

      if (!dashboard[categorie]) {
        dashboard[categorie] = {};
      }

      if (!dashboard[categorie][type]) {
        dashboard[categorie][type] = {
          type_id,
          PLANIFIE: 0,
          EN_COURS: 0,
          TERMINE: 0
        };
      }

      dashboard[categorie][type][etat] = total;
    }

    return dashboard;
  }

}

module.exports = DashboardService;