const db = require('../db'); // connexion MySQL2/promise

class DashboardService {


  //   static async getDashboardInterventions() {

  //   const sql = `
  //     SELECT
  //       ti.id AS type_id,
  //       ti.categorie,
  //       ti.libelle AS type,

  //       SUM(CASE WHEN i.date_debut_intervention IS NOT NULL THEN 1 ELSE 0 END) AS PLANIFIE,
  //       SUM(CASE WHEN i.date_debut_intervention IS NULL AND LOWER(i.etat) LIKE '%cours%' THEN 1 ELSE 0 END) AS EN_COURS,
  //       SUM(CASE WHEN i.date_debut_intervention IS NULL AND LOWER(i.etat) LIKE 'terminee_avec_succes%' THEN 1 ELSE 0 END) AS TERMINE,
  //       COUNT(*) AS TOTAL

  //     FROM intervention i
  //     JOIN intervention_type ti ON ti.id = i.type_id

  //     WHERE ti.actif = 1
  //       AND i.archive = 0
  //       -- ignore "terminee_avec_interruption" seulement si date_debut_intervention IS NULL
  //       AND NOT (i.date_debut_intervention IS NULL AND LOWER(i.etat) LIKE 'terminee_avec_interruption%')

  //     GROUP BY ti.id, ti.categorie, ti.libelle
  //     ORDER BY ti.categorie, ti.libelle
  //   `;

  //   const [rows] = await db.query(sql);

  //   // Transformation pour Angular dashboard
  //   const dashboard = {};

  //   for (const row of rows) {
  //     const { categorie, type, type_id, PLANIFIE, EN_COURS, TERMINE, TOTAL } = row;

  //     if (!dashboard[categorie]) dashboard[categorie] = {};

  //     dashboard[categorie][type] = {
  //       type_id,
  //       PLANIFIE,
  //       EN_COURS,
  //       TERMINE,
  //       TOTAL
  //     };
  //   }

  //   return dashboard;
  // }

  static async getDashboardInterventions() {
    const sql = `
    SELECT
      ti.id AS type_id,
      ti.categorie,
      ti.libelle AS type,
      SUM(CASE WHEN i.date_debut_intervention IS NOT NULL THEN 1 ELSE 0 END) AS PLANIFIE,
      SUM(CASE WHEN i.date_debut_intervention IS NULL AND LOWER(i.etat) LIKE '%cours%' THEN 1 ELSE 0 END) AS EN_COURS,
      SUM(CASE WHEN i.date_debut_intervention IS NULL AND LOWER(i.etat) LIKE 'terminee_avec_succes%' THEN 1 ELSE 0 END) AS TERMINE,
      COUNT(*) AS TOTAL

    FROM intervention i
    JOIN intervention_type ti ON ti.id = i.type_id

    WHERE ti.actif = 1
      AND i.archive = 0
      AND NOT (i.date_debut_intervention IS NULL AND LOWER(i.etat) LIKE 'terminee_avec_interruption%')

    GROUP BY ti.id, ti.categorie, ti.libelle
    
    -- CONDITION CRUCIALE : On filtre pour n'avoir que les lignes où au moins un compteur est > 0
    HAVING (PLANIFIE > 0 OR EN_COURS > 0 OR TERMINE > 0)
    
    ORDER BY ti.categorie, ti.libelle
  `;

    const [rows] = await db.query(sql);

    const dashboard = {};

    for (const row of rows) {
      const { categorie, type, type_id, PLANIFIE, EN_COURS, TERMINE, TOTAL } = row;

      if (!dashboard[categorie]) dashboard[categorie] = {};

      dashboard[categorie][type] = {
        type_id,
        PLANIFIE: String(PLANIFIE),
        EN_COURS: String(EN_COURS),
        TERMINE: String(TERMINE),
        TOTAL: Number(TOTAL)
      };
    }

    return dashboard;
  }

}

module.exports = DashboardService;