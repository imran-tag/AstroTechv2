const pool = require('../db'); // connexion MySQL2/promise
const HabitationService = require('../client_api/services/habitation.services');
const SecteurService = require('../client_api/services/secteur.services');
const ClientsService = require('../client_api/services/clients.services');


class InterventionService {

  /**
   * 🔹 Créer une nouvelle intervention
   */
  // Service
  static async apiCreate(data) {
    const safeData = {
      numero: Number(data.numero || 0),
      titre: data.titre || '',
      type_id: data.type_id || '',
      description: data.description || '',

      client_id: data.client_id != null ? Number(data.client_id) : null,
      zone_intervention_client_id: data.zone_intervention_client_id != null ? Number(data.zone_intervention_client_id) : null,
      type_client_zone_intervention: data.type_client_zone_intervention || '',

      priorite: data.priorite || '',
      etat: data.etat || '',

      date_butoir_realisation: data.date_butoir_realisation || null,
      date_cloture_estimee: data.date_cloture_estimee || null,

      mots_cles: Array.isArray(data.mots_cles) ? JSON.stringify(data.mots_cles) : (data.mots_cles || ''),

      montant_intervention: Number(data.montant_intervention || 0),
      montant_main_oeuvre: Number(data.montant_main_oeuvre || 0),
      montant_fournitures: Number(data.montant_fournitures || 0),

      referents: Array.isArray(data.referents) ? data.referents.map(Number) : [],

      createur_id: data.createur_id != null ? Number(data.createur_id) : null
    };

    const connection = await pool.getConnection();

    try {
      await connection.beginTransaction();

      const insertQuery = `
      INSERT INTO intervention (
        numero,
        titre,
        type_id,
        description,
        client_id,
        zone_intervention_client_id,
        type_client_zone_intervention,
        priorite,
        etat,
        date_butoir_realisation,
        date_cloture_estimee,
        mots_cles,
        montant_intervention,
        montant_main_oeuvre,
        montant_fournitures,
        createur_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

      const values = [
        safeData.numero,
        safeData.titre,
        safeData.type_id,
        safeData.description,

        safeData.client_id,
        safeData.zone_intervention_client_id,
        safeData.type_client_zone_intervention,

        safeData.priorite,
        safeData.etat,
        safeData.date_butoir_realisation,
        safeData.date_cloture_estimee,

        safeData.mots_cles,
        safeData.montant_intervention,
        safeData.montant_main_oeuvre,
        safeData.montant_fournitures,

        safeData.createur_id
      ];

      const [result] = await connection.query(insertQuery, values);
      const interventionId = result.insertId;

      if (safeData.referents.length > 0) {
        const refValues = safeData.referents.map(refId => [
          interventionId,
          refId,
          safeData.createur_id
        ]);

        await connection.query(
          `INSERT INTO intervention_referent (intervention_id, referent_id, createur_id) VALUES ?`,
          [refValues]
        );
      }

      await connection.commit();
      return { id: interventionId };

    } catch (error) {
      await connection.rollback();
      console.error('❌ Erreur création intervention:', error);
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
        )
      `;
        const like = `%${search}%`;
        params.push(like, like, like);
      }

      /* ===================== QUERY ===================== */
      const sql = `
      SELECT SQL_CALC_FOUND_ROWS
        i.*,
        it.libelle AS type_intervention   -- <-- ajout type_intervention
      FROM intervention i
      LEFT JOIN intervention_type it ON it.id = i.type_id  -- <-- jointure
      ${whereClause}
      ORDER BY i.id DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

      const [rows] = await pool.query(sql, params);

      /* ===================== TOTAL ===================== */
      const [[{ total }]] = await pool.query(`SELECT FOUND_ROWS() AS total`);

      /* ===================== REFERENTS & TECHNICIENS ===================== */
      for (const intervention of rows) {
        const interventionId = intervention.id;

        const [referents] = await pool.query(
          `
        SELECT r.id, r.nom, r.prenom, r.email, r.telephone
        FROM referent r
        JOIN intervention_referent ir ON r.id = ir.referent_id
        WHERE ir.intervention_id = ?
        `,
          [interventionId]
        );

        const [techniciens] = await pool.query(
          `
        SELECT t.id, t.nom, t.prenom, it.role
        FROM technicien t
        JOIN intervention_technicien it ON t.id = it.id_technicien
        WHERE it.id_intervention = ?
        `,
          [interventionId]
        );

        intervention.referents = referents;
        intervention.referent_ids = referents.map(r => r.id);
        intervention.techniciens = techniciens;

        // si type_intervention est null, mettre "Non défini"
        intervention.type_intervention = intervention.type_intervention || 'Non défini';
      }

      return {
        total,
        data: rows
      };

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

    const allowedFields = [
      'titre', 'description', 'numero', 'type_id',
      'priorite', 'etat', 'date_butoir_realisation',
      'date_cloture_estimee', 'mots_cles',
      'montant_intervention', 'montant_main_oeuvre',
      'montant_fournitures', 'date_prevue',
      'duree_heures', 'duree_minutes',
      'id_affaire', 'adresse_id',
      'zone_intervention_client_id',
      'type_client_zone_intervention',
      'createur_id'
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

      // 🔹 Mise à jour de l’intervention
      if (fields.length > 0) {
        await connection.query(
          `UPDATE intervention SET ${fields.join(', ')} WHERE id = ?`,
          [...values, id]
        );
      }

      // 🔹 Gestion des référents (SEULEMENT SI ENVOYÉS)
      if (Array.isArray(data.referent_ids)) {

        // Référents actuels
        const [rows] = await connection.query(
          'SELECT referent_id FROM intervention_referent WHERE intervention_id = ?',
          [id]
        );

        const currentReferents = rows.map(r => r.referent_id);
        const newReferents = data.referent_ids;

        // 🔍 Vérifier changement réel
        const hasChanged = !this.arraysEqual(currentReferents, newReferents);

        console.log('🔄 Référents modifiés ?', hasChanged);

        if (hasChanged) {
          // Supprimer anciens liens
          await connection.query(
            'DELETE FROM intervention_referent WHERE intervention_id = ?',
            [id]
          );

          // Insérer nouveaux liens
          if (newReferents.length > 0) {
            const insertValues = newReferents.map(refId => [id, refId]);

            await connection.query(
              'INSERT INTO intervention_referent (intervention_id, referent_id) VALUES ?',
              [insertValues]
            );
          }
        }
      }

      // 🔹 Récupérer intervention mise à jour
      const [updated] = await connection.query(
        'SELECT * FROM intervention WHERE id = ?',
        [id]
      );

      await connection.commit();
      return updated[0];

    } catch (error) {
      await connection.rollback();
      console.error('❌ updateIntervention:', error);
      throw error;
    } finally {
      connection.release();
    }
  }

  /**
   * 🔹 Supprimer une intervention
   */
  static async apiDeleteById(id) {
    const [result] = await pool.query('DELETE FROM intervention WHERE id = ?', [id]);
    return result.affectedRows > 0;
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

      // valeur par défaut
      intervention.type_intervention = intervention.type_intervention || 'Non défini';

      const clientId = intervention.client_id ?? null;
      const zoneClientId = intervention.zone_intervention_client_id ?? null;
      const typeClientZone = intervention.type_client_zone_intervention;
      const equipeId = intervention.equipe_id ?? null;

      /* ===================== 🔹 ZONE D’INTERVENTION ===================== */
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

      /* ===================== 🔹 CLIENT ===================== */
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
      /* ===================== VALIDATION ===================== */
      page = Number(page);
      limit = Number(limit);
      if (!Number.isInteger(page) || page < 1) page = 1;
      if (!Number.isInteger(limit) || limit < 1) limit = 10;
      const offset = (page - 1) * limit;

      /* ===================== WHERE + PARAMS ===================== */
      let whereClause = `
      WHERE i.type_id = ?
        AND i.createur_id = ?
    `;
      const params = [Number(type_id), Number(user_id)];

      if (etat) {
        whereClause += ` AND LOWER(i.etat) = ? `;
        params.push(etat.toLowerCase());
      }

      /* ===================== TOTAL ===================== */
      const countQuery = `
      SELECT COUNT(DISTINCT i.id) AS total
      FROM intervention i
      ${whereClause}
    `;
      const [[{ total }]] = await pool.execute(countQuery, params);

      /* ===================== DATA ===================== */
      const dataQuery = `
      SELECT
        i.id,
        i.numero,
        i.titre,
        i.description,
        i.etat,
        i.priorite,
        i.date_prevue,
        i.date_cloture_estimee,
        i.date_butoir_realisation,

        i.client_id,
        i.zone_intervention_client_id,
        i.type_client_zone_intervention,
        i.equipe_id,

        c.numero,
        c.compte,
        COALESCE(p.nom_complet, a.nom_agence, o.nom_entreprise) AS nomClient,
        CASE
          WHEN p.id IS NOT NULL THEN 'particulier'
          WHEN a.id IS NOT NULL THEN 'agence'
          WHEN o.id IS NOT NULL THEN 'organisation'
          ELSE 'inconnu'
        END AS typeClient

      FROM (
        SELECT i.id
        FROM intervention i
        ${whereClause}
        ORDER BY i.id DESC
        LIMIT ${limit} OFFSET ${offset}
      ) AS limited

      JOIN intervention i ON i.id = limited.id
      LEFT JOIN client c ON c.id = i.client_id
      LEFT JOIN particulier p ON p.client_id = c.id
      LEFT JOIN agence a ON a.client_id = c.id
      LEFT JOIN organisation o ON o.client_id = c.id

      ORDER BY i.id DESC
    `;

      const [interventions] = await pool.execute(dataQuery, params);


      /* ===================== 🔹 ZONE D’INTERVENTION ===================== */
      for (const intervention of interventions) {
        const zoneClientId = intervention.zone_intervention_client_id ?? null;
        const typeClientZone = intervention.type_client_zone_intervention;

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
              default: {
                zoneDetails = await ClientsService.getRecordDetails(zoneClientId);
              }
            }
          } catch (err) {
            console.warn(
              `Zone d’intervention introuvable (ID=${zoneClientId}, type=${typeClientZone})`
            );
            zoneDetails = null;
          }
        }

        // ✅ Affectation correcte pour éviter {data: {data: null}}
        intervention.zone_intervention = zoneDetails ?? null;
      }

      /* ===================== FORMAT FINAL ===================== */
      const data = interventions.map(i => ({
        id: i.id,
        titre: i.titre,
        numero: i.numero,
        description: i.description,
        etat: i.etat,
        priorite: i.priorite,
        date_prevue: i.date_prevue,
        date_cloture_estimee: i.date_cloture_estimee,
        date_butoir_realisation: i.date_butoir_realisation,

        client: i.client_id ? {
          id: i.client_id,
          numero: i.numero,
          compte: i.compte,
          nom: i.nomClient,
          type: i.typeClient
        } : null,

        zone_intervention: i.zone_intervention,
        equipe_id: i.equipe_id
      }));

      /* ===================== RETURN ===================== */
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
      console.error('Erreur apiGetByTypePaginated:', err);
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

  // static async apiGetDetails(interventionId) {
  //   try {

  //     // 🔹 Requête principale intervention
  //     const sql = `
  //     SELECT *
  //     FROM intervention
  //     WHERE id = ?
  //   `;

  //     const [rows] = await pool.execute(sql, [interventionId]);

  //     if (rows.length === 0) {
  //       return { message: "Intervention non trouvée" };
  //     }

  //     const intervention = rows[0];

  //     // 🔹 Workflow
  //     const [workflow] = await pool.execute(
  //       `SELECT * FROM intervention_workflow WHERE intervention_id = ?`,
  //       [interventionId]
  //     );
  //     intervention.workflow = workflow[0] || null;

  //     // 🔹 Photos
  //     const [photos] = await pool.execute(
  //       `SELECT id, photo_type, filename, url, latitude, longitude, comment, captured_at
  //      FROM intervention_photos
  //      WHERE intervention_id = ?
  //      ORDER BY captured_at ASC`,
  //       [interventionId]
  //     );

  //     intervention.photos = {
  //       before: photos.filter(p => p.photo_type === 'before'),
  //       after: photos.filter(p => p.photo_type === 'after'),
  //       additional_work: photos.filter(p => p.photo_type === 'additional_work'),
  //       delivery_note: photos.filter(p => p.photo_type === 'delivery_note'),
  //       quote: photos.filter(p => p.photo_type === 'quote')
  //     };

  //     // 🔹 Signatures
  //     const [signatures] = await pool.execute(
  //       `SELECT signature_type, signature_data, signed_at
  //      FROM intervention_signatures
  //      WHERE intervention_id = ?`,
  //       [interventionId]
  //     );

  //     intervention.signatures = {
  //       technician: signatures.find(s => s.signature_type === 'technician') || null,
  //       client: signatures.find(s => s.signature_type === 'client') || null,
  //       additional_work: signatures.find(s => s.signature_type === 'additional_work') || null,
  //       quote: signatures.find(s => s.signature_type === 'quote') || null
  //     };

  //     // 🔹 Interruptions
  //     const [interruptions] = await pool.execute(
  //       `SELECT id, reason, custom_reason, started_at, ended_at, duration_minutes
  //      FROM intervention_interruptions
  //      WHERE intervention_id = ?
  //      ORDER BY started_at ASC`,
  //       [interventionId]
  //     );

  //     intervention.interruptions = interruptions || [];

  //     return intervention;

  //   } catch (err) {
  //     console.error("Erreur apiGetDetails:", err);
  //     throw err;
  //   }
  // }

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