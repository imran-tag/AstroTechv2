const pool = require('../db'); // connexion MySQL2/promise
const HabitationService = require('../client_api/services/habitation.services');
const SecteurService = require('../client_api/services/secteur.services');
const ClientsService = require('../client_api/services/clients.services');


class InterventionService {

  /**
   * 🔹 Créer une nouvelle intervention
   */
  // Service
  // Dans votre Service

  static async apiCreate(data) {

    const safeData = {
      numero: data.numero != null ? String(data.numero) : '',
      titre: data.titre || '',
      type_id: data.type_id != null ? Number(data.type_id) : null,
      description: data.description || '',
      client_id: data.client_id != null ? Number(data.client_id) : null,
      zone_intervention_client_id: data.zone_intervention_client_id != null ? Number(data.zone_intervention_client_id) : null,
      type_client_zone_intervention: data.type_client_zone_intervention || '',
      priorite: data.priorite || 'moyenne',
      etat: data.etat || 'en_cours',
      date_butoir_realisation: data.date_butoir_realisation || null,
      date_cloture_estimee: data.date_cloture_estimee || null,
      montant_intervention: Number(data.montant_intervention || 0),
      montant_main_oeuvre: Number(data.montant_main_oeuvre || 0),
      montant_fournitures: Number(data.montant_fournitures || 0),
      createur_id: data.createur_id != null ? Number(data.createur_id) : null,

      // On s'assure de prendre "referent_ids" ou "referents" selon ce qui arrive
      referents: Array.isArray(data.referent_ids) ? data.referent_ids : (Array.isArray(data.referents) ? data.referents : []),

      // On prend "motsCles" tel quel depuis votre JSON
      motsCles: Array.isArray(data.motsCles) ? data.motsCles : []
    };

    const connection = await pool.getConnection();

    try {
        await connection.beginTransaction();

      // 1. Insertion de l'intervention
      const insertQuery = `
            INSERT INTO intervention (
                numero, titre, type_id, description,
                client_id, zone_intervention_client_id, type_client_zone_intervention,
                priorite, etat, date_butoir_realisation, date_cloture_estimee,
                montant_intervention, montant_main_oeuvre, montant_fournitures,
                createur_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

      const [result] = await connection.execute(insertQuery, [
        safeData.numero, safeData.titre, safeData.type_id, safeData.description,
        safeData.client_id, safeData.zone_intervention_client_id, safeData.type_client_zone_intervention,
        safeData.priorite, safeData.etat, safeData.date_butoir_realisation, safeData.date_cloture_estimee,
        safeData.montant_intervention, safeData.montant_main_oeuvre, safeData.montant_fournitures,
        safeData.createur_id
      ]);

      const interventionId = result.insertId;

      // 2. Insertion des Référents
      if (safeData.referents.length > 0) {
        const refValues = safeData.referents.map(refId => [interventionId, Number(refId), safeData.createur_id]);
        await connection.query(
          "INSERT INTO intervention_referent (intervention_id, referent_id, createur_id) VALUES ?",
          [refValues]
        );
      }

      // 3. ✅ INSERTION DES MOTS-CLÉS (La partie qui bloquait)
      if (safeData.motsCles.length > 0) {
        const valuesMots = safeData.motsCles.map(val => {
          // Test robuste : si c'est un nombre (ex: 2) ou une string qui contient un nombre (ex: "2")
          const isNumeric = (typeof val === 'number') || (typeof val === 'string' && /^\d+$/.test(val.trim()));

          return [
            isNumeric ? Number(val) : null,       // mot_cle_id
            interventionId,                       // target_id
            !isNumeric ? String(val) : null,      // libelle_custom
            'INTERVENTION'                        // target_type
          ];
        });

        const motCleQuery = `
                INSERT INTO mot_cle_liens (mot_cle_id, target_id, libelle_custom, target_type) 
                VALUES ?
            `;
        // Note : on utilise connection.query pour les "VALUES ?" avec mysql2
        await connection.query(motCleQuery, [valuesMots]);
      }

      await connection.commit();
      return { id: interventionId, ...safeData };

    } catch (error) {
      await connection.rollback();
      console.error("❌ Erreur dans apiCreate (Intervention):", error);
      throw error;
    } finally {
        connection.release();
    }
  }

  static async apiGetAllPaginated({ page = 1, limit = 10, search = '', userId }) {
    try {
      if (!userId) throw new Error('userId manquant');

      page = Number(page);
      limit = Number(limit);
      if (!Number.isInteger(page) || page < 1) page = 1;
      if (!Number.isInteger(limit) || limit < 1) limit = 10;

      const offset = (page - 1) * limit;

      /* ===================== CONDITIONS ===================== */
      let whereClause = `WHERE i.createur_id = ?`;
      const params = [userId];

      if (search && search.trim() !== '') {
        whereClause += `
        AND (
          i.titre LIKE ?
          OR i.description LIKE ?
          OR i.numero LIKE ?
          OR mc.libelle LIKE ?
          OR imc.libelle_custom LIKE ?
        )
      `;
        const like = `%${search}%`;
        params.push(like, like, like, like, like);
      }

      /* ===================== QUERY PRINCIPALE ===================== */
      const sql = `
      SELECT SQL_CALC_FOUND_ROWS
        i.*,
        it.libelle AS type_intervention
      FROM intervention i
      LEFT JOIN intervention_type it ON it.id = i.type_id
      /* Jointure avec la table de liens : mot_cle_liens */
      LEFT JOIN mot_cle_liens imc ON imc.target_id = i.id AND imc.target_type = 'INTERVENTION'
      /* Jointure avec la table de référence : mots_cles */
      LEFT JOIN mots_cles mc ON mc.id = imc.mot_cle_id
      ${whereClause}
      GROUP BY i.id 
      ORDER BY i.id DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

      const [rows] = await pool.query(sql, params);

      /* ===================== TOTAL ===================== */
      const [[{ total }]] = await pool.query(`SELECT FOUND_ROWS() AS total`);

      /* ===================== DÉTAILS PAR INTERVENTION ===================== */
      for (const intervention of rows) {
        const interventionId = intervention.id;
        const clientId = intervention.client_id ?? null;
        const equipeId = intervention.equipe_id ?? null;

        // 1. Référents
        const [referents] = await pool.query(
          `SELECT r.id, r.nom, r.prenom, r.email, r.telephone
         FROM referent r
         JOIN intervention_referent ir ON r.id = ir.referent_id
         WHERE ir.intervention_id = ?`,
          [interventionId]
        );
        intervention.referents = referents || [];
        intervention.referent_ids = (referents || []).map(r => r.id);

        // 2. Techniciens individuels
        const [techniciens] = await pool.query(
          `SELECT t.id, t.nom, t.prenom, it.role
         FROM technicien t
         JOIN intervention_technicien it ON t.id = it.id_technicien
         WHERE it.id_intervention = ?`,
          [interventionId]
        );
        intervention.techniciens = techniciens || [];

        // 3. Client (Supposant que ClientsService est disponible)
        intervention.client = null;
        if (clientId) {
          try {
            intervention.client = await ClientsService.getRecordDetails(clientId);
          } catch (err) {
            console.warn(`Client ${clientId} introuvable pour l'intervention ${interventionId}`);
          }
        }

        // 4. Équipe et Chef
        intervention.equipe = null;
        if (equipeId) {
          const [equipeRows] = await pool.execute(
            `SELECT 
            eq.id AS equipeId, eq.nom AS equipeNom, eq.description AS equipeDescription, eq.chefId,
            chef.nom AS chefNom, chef.prenom AS chefPrenom, chef.telephone AS chefTelephone, chef.email AS chefEmail
          FROM equipe_technicien eq
          LEFT JOIN technicien chef ON chef.id = eq.chefId
          WHERE eq.id = ?`,
            [equipeId]
          );

          if (equipeRows.length > 0) {
            const e = equipeRows[0];
            intervention.equipe = {
              id: e.equipeId,
              nom: e.equipeNom,
              description: e.equipeDescription,
              chef: e.chefId ? {
                id: e.chefId, nom: e.chefNom, prenom: e.chefPrenom,
                telephone: e.chefTelephone, email: e.chefEmail
              } : null
            };
          }
        }

        // 5. Mots-clés (Correction des noms de tables ici aussi)
        const [motsCles] = await pool.query(
          `SELECT 
            mc.id, 
            COALESCE(mc.libelle, imc.libelle_custom) AS libelle
         FROM mot_cle_liens imc
         LEFT JOIN mots_cles mc ON mc.id = imc.mot_cle_id
         WHERE imc.target_id = ? AND imc.target_type = 'INTERVENTION'`,
          [interventionId]
        );
        intervention.techniciens = techniciens || [];

        intervention.motsClesDetails = motsCles || [];
        intervention.motsCles = (motsCles || []).map(m => m.id || m.libelle);
        intervention.type_intervention = intervention.type_intervention || 'Non défini';
      }

      return { total, data: rows };

    } catch (err) {
      console.error('Erreur apiGetAllPaginated:', err);
      throw err;
    }
  }

  /**
   * 🔧 Compare deux tableaux (sans tenir compte de l'ordre)
   */
  static arraysEqual(a = [], b = []) {
    if (!Array.isArray(a) || !Array.isArray(b)) return false;
    if (a.length !== b.length) return false;

    const s1 = [...a].sort();
    const s2 = [...b].sort();

    return s1.every((v, i) => v === s2[i]);
  }

  /**
   * 🔹 Modifier une intervention
   * 🔍 Met à jour intervention_referent seulement si changement réel
   */
  static async updateIntervention(id, data) {
    if (!data || Object.keys(data).length === 0) return null;

    // Liste des champs autorisés pour la table principale
    const allowedFields = [
      'titre', 'description', 'numero', 'type_id',
      'priorite', 'etat', 'date_butoir_realisation',
      'date_cloture_estimee', 'montant_intervention',
      'montant_main_oeuvre', 'montant_fournitures', 'createur_id'
    ];

    const fields = [];
    const values = [];

    for (const key of allowedFields) {
      if (key in data) {
        fields.push(`${key} = ?`);
        values.push(data[key] !== undefined ? data[key] : null);
      }
    }

    const connection = await pool.getConnection();

    try {
      await connection.beginTransaction();

      // 1. Mise à jour de la table intervention
      if (fields.length > 0) {
        await connection.query(
          `UPDATE intervention SET ${fields.join(', ')} WHERE id = ?`,
          [...values, id]
        );
      }

      // 2. Mise à jour des RÉFÉRENTS (Sync par Delete/Insert)
      if (Array.isArray(data.referents)) {
        await connection.query('DELETE FROM intervention_referent WHERE intervention_id = ?', [id]);

        if (data.referents.length > 0) {
          const refValues = data.referents.map(refId => [id, Number(refId)]);
          await connection.query(
            'INSERT INTO intervention_referent (intervention_id, referent_id) VALUES ?',
            [refValues]
          );
        }
      }

      // 3. Mise à jour des MOTS-CLÉS (Sync par Delete/Insert)
      if (Array.isArray(data.motsCles)) {
        // On cible bien uniquement les liens de cette intervention
        await connection.query(
          'DELETE FROM mot_cle_liens WHERE target_id = ? AND target_type = "INTERVENTION"',
          [id]
        );

        const cleanedMots = data.motsCles.filter(v => v !== null && String(v).trim() !== '');

        if (cleanedMots.length > 0) {
          const valuesMots = cleanedMots.map(val => {
            // Détection : ID (nombre) ou Libellé (texte)
            const isNumeric = (typeof val === 'number') || (typeof val === 'string' && /^\d+$/.test(val.trim()));

            return [
              isNumeric ? Number(val) : null,
              id,
              !isNumeric ? String(val) : null,
              'INTERVENTION'
            ];
          });

          await connection.query(
            "INSERT INTO mot_cle_liens (mot_cle_id, target_id, libelle_custom, target_type) VALUES ?",
            [valuesMots]
          );
        }
      }

      await connection.commit();

      // 4. Récupérer l'objet mis à jour pour le renvoyer au front
      const [updated] = await connection.query('SELECT * FROM intervention WHERE id = ?', [id]);
      return updated[0];

    } catch (error) {
      await connection.rollback();
      console.error('❌ Service Update Error:', error);
      throw error;
    } finally {
      connection.release();
    }
  }

  /**
   * 🔹 Supprimer une intervention
   */
  static async apiDeleteById(id) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      // 1. Supprimer les liaisons avec les référents
      await connection.query(
        'DELETE FROM intervention_referent WHERE intervention_id = ?',
        [id]
      );

      // 2. Supprimer les liaisons avec les mots-clés
      // On précise target_type pour ne pas toucher aux autres entités (Affaires, etc.)
      await connection.query(
        'DELETE FROM mot_cle_liens WHERE target_id = ? AND target_type = "INTERVENTION"',
        [id]
      );

      // 3. Supprimer l'intervention elle-même
      const [result] = await connection.query(
        'DELETE FROM intervention WHERE id = ?',
        [id]
      );

      await connection.commit();

      // Retourne true si l'intervention existait et a été supprimée
      return result.affectedRows > 0;

    } catch (error) {
      await connection.rollback();
      console.error("❌ Error during apiDeleteById:", error.message);
      throw error;
    } finally {
      connection.release();
    }
  }

  // 🔹 Obtenir le prochain numéro
  static async getNextNumero() {
    try {
      const [rows] = await pool.query(
        "SELECT MAX(numero) AS maxNumero FROM intervention"
      );
      const nextNumero = (rows[0].maxNumero || 0) + 1;
      return nextNumero;
    } catch (error) {
      console.error("Erreur getNextNumero:", error);
      throw error;
    }
  }

  // Assigner des techniciens à une intervention
  static async assignTechniciens(interventionId, techniciens) {
    // 🔹 Supprimer l'équipe associée avant d'affecter des techniciens
    await pool.query('UPDATE intervention SET equipe_id = NULL WHERE id = ?', [interventionId]);

    // 🔹 Supprimer d'abord les techniciens existants pour cette intervention
    await pool.query('DELETE FROM intervention_technicien WHERE id_intervention = ?', [interventionId]);

    // 🔹 Ré-affecter les techniciens
    if (techniciens.length > 0) {
      const values = techniciens.map(techId => [interventionId, techId]);
      await pool.query(
        'INSERT INTO intervention_technicien (id_intervention, id_technicien) VALUES ?',
        [values]
      );
    }

    return { interventionId, techniciens };
  }

  static async addPlanning(interventionId, planning) {
    const { date, heure } = planning;
    const sql = `
    INSERT INTO intervention_planning (intervention_id, date, heure)
    VALUES (?, ?, ?)
  `;
    await pool.query(sql, [interventionId, date, heure]);
    return { interventionId, date, heure };
  }

  // Nouvelle méthode pour assigner une équipe
  static async assignEquipe(interventionId, equipe_id) {
    try {
      if (!equipe_id) {
        throw new Error('equipe_id est requis');
      }

      // Supprimer d'abord les techniciens existants pour cette intervention
      await pool.query('DELETE FROM intervention_technicien WHERE id_intervention = ?', [interventionId]);

      // Mise à jour de la colonne equipe_id dans la table intervention
      const query = `UPDATE intervention SET equipe_id = ? WHERE id = ?`;
      const [result] = await pool.query(query, [equipe_id, interventionId]);

      // Retourne juste le résultat de la requête
      return result;

    } catch (error) {
      console.error('Erreur assignEquipe:', error);
      throw error; // 🔹 lance l'erreur pour que le controller la gère
    }
  }

  static async apiGetById(id) {
    try {
      /* ===================== 🔹 INTERVENTION + TYPE ===================== */
      const [interventions] = await pool.execute(
        `
            SELECT 
                i.*,
                it.libelle AS type_intervention
            FROM intervention i
            LEFT JOIN intervention_type it ON it.id = i.type_id
            WHERE i.id = ?
            `,
        [id]
      );

      if (interventions.length === 0) return null;
      const intervention = interventions[0];

      // Valeurs par défaut pour éviter les erreurs au front
      intervention.type_intervention = intervention.type_intervention || 'Non défini';
      const clientId = intervention.client_id ?? null;
      const zoneClientId = intervention.zone_intervention_client_id ?? null;
      const typeClientZone = intervention.type_client_zone_intervention;
      const equipeId = intervention.equipe_id ?? null;

      /* ===================== 🔹 RÉFÉRENTS ===================== */
      const [referents] = await pool.execute(
        `
            SELECT r.id, r.nom, r.prenom, r.email, r.telephone
            FROM referent r
            JOIN intervention_referent ir ON r.id = ir.referent_id
            WHERE ir.intervention_id = ?
            `,
        [id]
      );
      intervention.referents = referents || [];
      intervention.referent_ids = referents.map(r => r.id);

      /* ===================== 🔹 ✅ MOTS-CLÉS (FORMATAGE DÉTAILLÉ) ===================== */
      const [motsClesRows] = await pool.execute(
        `
            SELECT 
                mcl.mot_cle_id AS id, 
                mcl.libelle_custom,
                mc.libelle AS libelle_base
            FROM mot_cle_liens mcl
            LEFT JOIN mots_cles mc ON mc.id = mcl.mot_cle_id
            WHERE mcl.target_id = ? AND mcl.target_type = 'INTERVENTION'
            `,
        [id]
      );

      // On construit le tableau motsClesDetails tel que demandé
      intervention.motsClesDetails = motsClesRows.map(row => {
        return {
          id: row.id, // Sera un nombre ou null
          libelle: row.id ? row.libelle_base : row.libelle_custom
        };
      });

      // Optionnel : on garde aussi la version simple pour faciliter l'édition (Update)
      intervention.motsCles = motsClesRows.map(row => row.id ? row.id : row.libelle_custom);


      /* ===================== 🔹 ZONE D’INTERVENTION (Logique existante) ===================== */
      let zoneDetails = null;
      if (zoneClientId !== null) {
        try {
          switch (typeClientZone) {
            case 'habitation':
              zoneDetails = await HabitationService.getRecordDetails(zoneClientId);
              break;
            case 'secteur':
              zoneDetails = await SecteurService.getRecordDetails(zoneClientId);
              break;
            default:
              zoneDetails = await ClientsService.getRecordDetails(zoneClientId);
          }
        } catch (err) {
          console.warn(`Zone d’intervention introuvable :`, err.message);
          zoneDetails = null;
        }
      }
      intervention.zone_intervention = zoneDetails;

      /* ===================== 🔹 CLIENT (Logique existante) ===================== */
      let client = null;
      if (clientId !== null) {
        try {
          client = await ClientsService.getRecordDetails(clientId);
        } catch (err) {
          console.error(`Erreur récupération client :`, err.message);
          client = null;
        }
      }
      intervention.client = client;

      // ... Ajoutez ici la suite de votre code (Techniciens, Equipe, etc.) ...
        /* ===================== 🔹 TECHNICIENS INDIVIDUELS ===================== */
      const [techniciens] = await pool.execute(
        `
      SELECT t.id, t.nom, t.prenom, it.role
      FROM technicien t
      JOIN intervention_technicien it ON t.id = it.id_technicien
      WHERE it.id_intervention = ?
      `,
        [id]
      );
      intervention.techniciens = techniciens || [];

      /* ===================== 🔹 ÉQUIPE + CHEF + MEMBRES ===================== */
      let equipe = null;
      if (equipeId !== null) {
        const [rows] = await pool.execute(
          `
        SELECT 
          eq.id AS equipeId,
          eq.nom AS equipeNom,
          eq.description AS equipeDescription,
          eq.chefId,
          chef.nom AS chefNom,
          chef.prenom AS chefPrenom,
          chef.telephone AS chefTelephone,
          chef.email AS chefEmail,
          te.technicienId,
          t.nom AS technicienNom,
          t.prenom AS technicienPrenom,
          te.dateAffectation
        FROM equipe_technicien eq
        LEFT JOIN technicien_equipe te ON te.equipeId = eq.id
        LEFT JOIN technicien t ON t.id = te.technicienId
        LEFT JOIN technicien chef ON chef.id = eq.chefId
        WHERE eq.id = ?
        ORDER BY eq.id, t.nom
        `,
          [equipeId]
        );

        if (rows.length > 0) {
          equipe = {
            id: rows[0].equipeId,
            nom: rows[0].equipeNom,
            description: rows[0].equipeDescription,
            chef: rows[0].chefId
              ? {
                id: rows[0].chefId,
                nom: rows[0].chefNom,
                prenom: rows[0].chefPrenom,
                telephone: rows[0].chefTelephone,
                email: rows[0].chefEmail
              }
              : null,
            techniciens: []
          };

          rows.forEach(row => {
            if (row.technicienId && row.technicienId !== row.chefId) {
              equipe.techniciens.push({
                id: row.technicienId,
                nom: row.technicienNom,
                prenom: row.technicienPrenom,
                dateAffectation: row.dateAffectation
              });
            }
          });
        }
      }
      intervention.equipe = equipe;

      
      return intervention;

    } catch (err) {
      console.error('❌ Erreur apiGetById:', err);
      throw err;
    }
  }

  static async updateEtat({ interventionId, type, userId }) {
    try {
      const sql = `
        UPDATE intervention
        SET etat = ?
        WHERE id = ?
          AND createur_id = ?
      `;

      const [result] = await pool.query(sql, [
        type,
        interventionId,
        userId
      ]);

      return {
        updated: result.affectedRows > 0
      };

    } catch (err) {
      console.error("Erreur updateType service:", err);
      throw err;
    }
  }

  static async apiGetByTypePaginated({
    type_id,
    user_id,
    etat = null,
    page = 1,
    limit = 10
  }) {
    try {
      page = Number(page) || 1;
      limit = Number(limit) || 10;
      if (page < 1) page = 1;
      if (limit < 1) limit = 10;
      const offset = (page - 1) * limit;

      // 🔹 Conditions dynamiques
      const whereConditions = ["i.type_id = ?", "i.createur_id = ?"];
      const params = [Number(type_id), Number(user_id)];

      if (etat) {
        const etatLower = etat.toLowerCase();
        if (etatLower === "planifie") {
          whereConditions.push("i.date_debut_intervention IS NOT NULL");
        } else if (["en_cours", "terminee_avec_succes"].includes(etatLower)) {
          whereConditions.push("i.date_debut_intervention IS NULL");
          whereConditions.push("LOWER(i.etat) = ?");
          params.push(etatLower);
        } else {
          whereConditions.push("LOWER(i.etat) = ?");
          params.push(etatLower);
        }
      }

      const whereClause = `WHERE ${whereConditions.join(" AND ")}`;

      // 🔹 Total pagination
      const countQuery = `SELECT COUNT(*) AS total FROM intervention i ${whereClause}`;
      const [[{ total }]] = await pool.execute(countQuery, params);

      // 🔹 Récupération des interventions limitées
      const dataQuery = `
      SELECT i.*
      FROM (
        SELECT i.id
        FROM intervention i
        ${whereClause}
        ORDER BY i.id DESC
        LIMIT ${limit} OFFSET ${offset}
      ) limited
      JOIN intervention i ON i.id = limited.id
    `;
      const [interventions] = await pool.execute(dataQuery, params);

      // 🔹 Transformation et enrichissement des données
      const data = [];
      for (const i of interventions) {
        // Zone d’intervention
        let zone = null;
        if (i.zone_intervention_client_id) {
          try {
            switch (i.type_client_zone_intervention) {
              case 'habitation':
                zone = await HabitationService.getRecordDetails(i.zone_intervention_client_id);
                break;
              case 'secteur':
                zone = await SecteurService.getRecordDetails(i.zone_intervention_client_id);
                break;
              default:
                zone = await ClientsService.getRecordDetails(i.zone_intervention_client_id);
            }
          } catch (err) {
            console.warn(`Zone d’intervention introuvable pour ID ${i.zone_intervention_client_id}:`, err.message);
          }
        }

        // Client
        let client = null;
        if (i.client_id) {
          try {
            client = await ClientsService.getRecordDetails(i.client_id);
          } catch (err) {
            console.error(`Erreur récupération client ${i.client_id}:`, err.message);
          }
        }

        data.push({
          id: i.id,
          numero: i.numero,
          titre: i.titre,
          description: i.description,
          etat: i.etat,
          priorite: i.priorite,
          date_prevue: i.date_prevue,
          date_cloture_estimee: i.date_cloture_estimee,
          date_butoir_realisation: i.date_butoir_realisation,
          date_debut_intervention: i.date_debut_intervention,
          client,
          zone_intervention: zone,
          equipe_id: i.equipe_id
        });
      }

      return {
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit)
        },
        data
      };

    } catch (err) {
      console.error("Erreur apiGetByTypePaginated:", err);
      throw err;
    }
  }


  /**
* 🔹 Récupérer toutes les interventions
*/
  static async apiGetAll(userId) {
    try {
      /* ===================== INTERVENTIONS ===================== */
      const sql = `
      SELECT *
      FROM intervention
      WHERE createur_id = ?
      ORDER BY id DESC
    `;

      const [rows] = await pool.execute(sql, [userId]);

      for (const intervention of rows) {
        const interventionId = intervention.id;

        /* ===================== RÉFÉRENTS ===================== */
        const [referents] = await pool.execute(
          `
        SELECT r.id, r.nom, r.prenom, r.email, r.telephone
        FROM referent r
        JOIN intervention_referent ir ON r.id = ir.referent_id
        WHERE ir.intervention_id = ?
        `,
          [interventionId]
        );

        intervention.referents = referents || [];
        intervention.referent_ids = referents.map(r => r.id);

        /* ===================== TECHNICIENS ===================== */
        const [techniciens] = await pool.execute(
          `
        SELECT t.id, t.nom, t.prenom, it.role
        FROM technicien t
        JOIN intervention_technicien it
          ON t.id = it.id_technicien
        WHERE it.id_intervention = ?
        `,
          [interventionId]
        );

        intervention.techniciens = techniciens || [];
      }

      return rows;

    } catch (err) {
      console.error('Erreur apiGetAll:', err);
      throw err;
    }
  }

  static async getInterventionTypes() {
    try {
      const sql = `
      SELECT id, libelle, categorie
      FROM intervention_type
      WHERE actif = 1
      ORDER BY libelle ASC
    `;

      const [rows] = await pool.execute(sql);
      return rows;

    } catch (err) {
      console.error("Erreur getInterventionTypes:", err);
      throw err;
    }
  }

  static async addPrevision(interventionId, planning) {
    const { date_debut, duree_heures, duree_minutes } = planning;

    // Calcul de la date de fin prévisionnelle
    const dateDebut = new Date(date_debut);
    const dateFin = new Date(dateDebut.getTime() + (duree_heures * 60 + duree_minutes) * 60000);

    // Mettre à jour la table intervention
    const sql = `
        UPDATE intervention
        SET date_debut_prevue = ?, date_fin_prevue = ?, duree_prevue_heures = ?, duree_prevue_minutes = ?
        WHERE id = ?
    `;
    await pool.query(sql, [dateDebut, dateFin, duree_heures, duree_minutes, interventionId]);

    return { interventionId, date_debut: dateDebut, date_fin: dateFin, duree_heures, duree_minutes };
  }

  static async apiGetDetails(interventionId) {
    const [rows] = await pool.query(`SELECT *
FROM (

    -- 📷 Photos
    SELECT 
        intervention_id,
        'PHOTO' AS event_type,
        photo_type AS sub_type,
        captured_at AS event_date,
        filename AS description
    FROM intervention_photos
    WHERE intervention_id = ?

    UNION ALL

    -- ✍ Signatures
    SELECT 
        intervention_id,
        'SIGNATURE',
        signature_type,
        signed_at,
        NULL
    FROM intervention_signatures
    WHERE intervention_id = ?

    UNION ALL

    -- ⏸ Interruptions
    SELECT 
        intervention_id,
        'INTERRUPTION',
        reason,
        started_at,
        custom_reason
    FROM intervention_interruptions
    WHERE intervention_id = ?

    UNION ALL

    -- ✅ Workflow
    SELECT 
        intervention_id,
        'WORKFLOW',
        NULL,
        completed_at,
        comment
    FROM intervention_workflow
    WHERE intervention_id = ?

) history
ORDER BY event_date ASC;`, [
      interventionId, interventionId, interventionId, interventionId
    ]);

    const grouped = {};

    rows.forEach(event => {
      const day = event.event_date.toISOString().split('T')[0];

      if (!grouped[day]) {
        grouped[day] = [];
      }

      grouped[day].push(event);
    });

    return grouped;
  }

}

module.exports = InterventionService;