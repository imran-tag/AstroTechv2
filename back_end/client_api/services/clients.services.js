const db = require("../db"); // pool mysql2/promise

class ClientService {

  // Récupérer tous les clients avec nom_client et type_client
  static async getAllRecords() {
    const query = `
    SELECT 
      c.id,
      c.numero,
      c.compte,
      COALESCE(p.nom_complet, a.nom_agence, o.nom_entreprise) AS nom_client,
      CASE
        WHEN p.client_id IS NOT NULL THEN 'particulier'
        WHEN a.client_id IS NOT NULL THEN 'agence'
        WHEN o.client_id IS NOT NULL THEN 'organisation'
        ELSE 'inconnu'
      END AS type_client
    FROM client c
    LEFT JOIN particulier p ON p.client_id = c.id
    LEFT JOIN agence a ON a.client_id = c.id
    LEFT JOIN organisation o ON o.client_id = c.id
    WHERE c.parent_id IS NULL
    ORDER BY nom_client ASC;
    `;

    const [rows] = await db.query(query);
    return rows;
  }

  // 🔹 UPDATE CLIENT BY ID
  static async updateRecordById(record) {
    const { id, numero, compte } = record;

    const query = `
      UPDATE client
      SET numero = ?, compte = ?
      WHERE id = ?
    `;

    const [result] = await db.execute(query, [
      numero,
      compte,
      id
    ]);

    return {
      success: true,
      message: "Client mis à jour avec succès",
      affectedRows: result.affectedRows,
      data: record
    };
  }

  // Récupérer tous les clients avec contacts, emails et téléphones
  static async getAllClientsWithContacts() {
    try {
      const query = `
      SELECT 
        c.id AS clientId,
        c.numero,
        c.compte,
        COALESCE(p.nom_complet, a.nom_agence, o.nom_entreprise) AS nomClient,
        CASE
          WHEN p.id IS NOT NULL THEN 'particulier'
          WHEN a.id IS NOT NULL THEN 'agence'
          WHEN o.id IS NOT NULL THEN 'organisation'
          ELSE 'inconnu'
        END AS typeClient,
        p.id AS particulierId,
        p.email AS particulierEmail,
        p.telephone AS particulierTel,
        a.id AS agenceId,
        o.id AS organisationId,
        ad.id AS adresseId,
        ad.adresse,
        ad.code_postal,
        ad.ville,
        ad.province,
        ad.pays,
        ad.etage,
        ad.appartement_local,
        ad.batiment,
        ad.interphone_digicode,
        ad.escalier,
        ad.porte_entree,
        ct.id AS contactId,
        ct.nom_complet AS contactNomComplet,
        ct.poste,
        ct.date_du,
        ct.date_au,
        ct.memo_note,
        e.id AS emailId,
        e.email,
        e.type AS emailType,
        t.id AS telId,
        t.tel,
        t.type AS telType
      FROM client c
      LEFT JOIN particulier p ON p.client_id = c.id
      LEFT JOIN agence a ON a.client_id = c.id
      LEFT JOIN organisation o ON o.client_id = c.id
      LEFT JOIN adresse ad ON ad.id = p.adresse_id OR ad.id = a.adresse_id
      LEFT JOIN contact ct ON ct.client_id = c.id
      LEFT JOIN adresse_email e ON e.contact_id = ct.id
      LEFT JOIN num_tel t ON t.contact_id = ct.id

      -- 🔥 FILTRE : retourner seulement les clients qui ne sont pas des parents
      WHERE c.parent_id IS NULL

      ORDER BY c.id, ct.id;
    `;

      const [rows] = await db.execute(query);

      const clientsMap = new Map();

      rows.forEach(row => {
        if (!clientsMap.has(row.clientId)) {
          const clientData = {
            id: row.clientId,
            numero: row.numero,
            compte: row.compte,
            nom_client: row.nomClient,
            type_client: row.typeClient,
            particulier_id: row.particulierId,
            agence_id: row.agenceId,
            organisation_id: row.organisationId,
            type_parent: null,
            adresse: row.adresseId ? {
              id: row.adresseId,
              adresse: row.adresse,
              code_postal: row.code_postal,
              ville: row.ville,
              province: row.province,
              pays: row.pays,
              etage: row.etage,
              appartement_local: row.appartement_local,
              batiment: row.batiment,
              interphone_digicode: row.interphone_digicode,
              escalier: row.escalier,
              porte_entree: row.porte_entree
            } : null,
            contacts: []
          };

          if (row.typeClient === 'particulier') {
            clientData.email = row.particulierEmail;
            clientData.telephone = row.particulierTel;
          }

          clientsMap.set(row.clientId, clientData);
        }

        const client = clientsMap.get(row.clientId);

        if (row.contactId) {
          let contact = client.contacts.find(c => c.id === row.contactId);
          if (!contact) {
            contact = {
              id: row.contactId,
              nom_complet: row.contactNomComplet,
              poste: row.poste,
              date_du: row.date_du,
              date_au: row.date_au,
              memo_note: row.memo_note,
              listEmails: [],
              listTels: []
            };
            client.contacts.push(contact);
          }

          if (row.emailId && !contact.listEmails.some(e => e.id === row.emailId)) {
            contact.listEmails.push({
              id: row.emailId,
              email: row.email,
              type: row.emailType
            });
          }

          if (row.telId && !contact.listTels.some(t => t.id === row.telId)) {
            contact.listTels.push({
              id: row.telId,
              tel: row.tel,
              type: row.telType
            });
          }
        }
      });

      return Array.from(clientsMap.values());

    } catch (err) {
      console.error("Erreur getAllClientsWithContacts:", err);
      throw err;
    }
  }

  static async getAllClientsWithContactsPaginated({
    page = 1,
    limit = 10,
    search = '',
    userId = null
  }) {
    try {
      // 🔹 Validation
      page = Number(page);
      limit = Number(limit);
      if (!Number.isInteger(page) || page < 1) page = 1;
      if (!Number.isInteger(limit) || limit < 1) limit = 10;
      const offset = (page - 1) * limit;

      let whereClause = `WHERE c.parent_id IS NULL`;
      const params = [];

      if (search && search.trim() !== '') {
        const keyword = `%${search}%`;
        whereClause += `
        AND (
          c.numero LIKE ?
          OR COALESCE(p.nom_complet, a.nom_agence, o.nom_entreprise) LIKE ?
        )
      `;
        params.push(keyword, keyword);
      }

      if (userId) {
        whereClause += ` AND c.createur_id = ?`;
        params.push(userId);
      }

      /* =====================================================
         🔹 1 — TOTAL (sans pagination)
      ===================================================== */
      const countQuery = `
      SELECT COUNT(DISTINCT c.id) AS total
      FROM client c
      LEFT JOIN particulier p ON p.client_id = c.id
      LEFT JOIN agence a ON a.client_id = c.id
      LEFT JOIN organisation o ON o.client_id = c.id
      ${whereClause}
    `;

      const [[{ total }]] = await db.execute(countQuery, params);

      /* =====================================================
         🔹 2 — DONNÉES PAGINÉES
      ===================================================== */
      const dataQuery = `
      SELECT 
        c.id AS id,
        c.numero,
        c.compte,
        COALESCE(p.nom_complet, a.nom_agence, o.nom_entreprise) AS nomClient,
        CASE
          WHEN p.id IS NOT NULL THEN 'particulier'
          WHEN a.id IS NOT NULL THEN 'agence'
          WHEN o.id IS NOT NULL THEN 'organisation'
          ELSE 'inconnu'
        END AS typeClient,
        p.id AS particulierId,
        p.email AS particulierEmail,
        p.telephone AS particulierTel,
        a.id AS agenceId,
        o.id AS organisationId,
        ad.id AS adresseId,
        ad.adresse,
        ad.code_postal,
        ad.ville,
        ad.province,
        ad.pays,
        ad.etage,
        ad.appartement_local,
        ad.batiment,
        ad.interphone_digicode,
        ad.escalier,
        ad.porte_entree,
        ct.id AS contactId,
        ct.nom_complet AS contactNomComplet,
        ct.poste,
        ct.date_du,
        ct.date_au,
        ct.memo_note,
        e.id AS emailId,
        e.email,
        e.type AS emailType,
        t.id AS telId,
        t.tel,
        t.type AS telType
      FROM (
        SELECT c.id
        FROM client c
        LEFT JOIN particulier p ON p.client_id = c.id
        LEFT JOIN agence a ON a.client_id = c.id
        LEFT JOIN organisation o ON o.client_id = c.id
        ${whereClause}
        ORDER BY c.id
        LIMIT ${limit} OFFSET ${offset}
      ) AS limited_clients
      JOIN client c ON c.id = limited_clients.id
      LEFT JOIN particulier p ON p.client_id = c.id
      LEFT JOIN agence a ON a.client_id = c.id
      LEFT JOIN organisation o ON o.client_id = c.id
      LEFT JOIN adresse ad ON ad.id = p.adresse_id OR ad.id = a.adresse_id
      LEFT JOIN contact ct ON ct.client_id = c.id
      LEFT JOIN adresse_email e ON e.contact_id = ct.id
      LEFT JOIN num_tel t ON t.contact_id = ct.id
      ORDER BY c.id, ct.id
    `;

      const [rows] = await db.execute(dataQuery, params);

      /* =====================================================
         🔹 3 — FORMATAGE
      ===================================================== */
      const clientsMap = new Map();

      rows.forEach(row => {
        if (!clientsMap.has(row.id)) {
          const client = {
            id: row.id,
            numero: row.numero,
            compte: row.compte,
            nom_client: row.nomClient,
            type_client: row.typeClient,
            type_parent: null,
            particulier_id: row.particulierId,
            agence_id: row.agenceId,
            organisation_id: row.organisationId,
            adresse: row.adresseId ? {
              id: row.adresseId,
              adresse: row.adresse,
              code_postal: row.code_postal,
              ville: row.ville,
              province: row.province,
              pays: row.pays,
              etage: row.etage,
              appartement_local: row.appartement_local,
              batiment: row.batiment,
              interphone_digicode: row.interphone_digicode,
              escalier: row.escalier,
              porte_entree: row.porte_entree
            } : null,
            contacts: []
          };

          if (row.typeClient === 'particulier') {
            client.email = row.particulierEmail;
            client.telephone = row.particulierTel;
          }

          clientsMap.set(row.id, client);
        }

        const client = clientsMap.get(row.id);

        if (row.contactId) {
          let contact = client.contacts.find(c => c.id === row.contactId);
          if (!contact) {
            contact = {
              id: row.contactId,
              nom_complet: row.contactNomComplet,
              poste: row.poste,
              date_du: row.date_du,
              date_au: row.date_au,
              memo_note: row.memo_note,
              listEmails: [],
              listTels: []
            };
            client.contacts.push(contact);
          }

          if (row.emailId && !contact.listEmails.some(e => e.id === row.emailId)) {
            contact.listEmails.push({ id: row.emailId, email: row.email, type: row.emailType });
          }

          if (row.telId && !contact.listTels.some(t => t.id === row.telId)) {
            contact.listTels.push({ id: row.telId, tel: row.tel, type: row.telType });
          }
        }
      });

      /* =====================================================
         🔹 4 — RETURN FINAL
      ===================================================== */
      return {
        total,
        data: Array.from(clientsMap.values())
      };

    } catch (err) {
      console.error("Erreur getAllClientsWithContactsPaginated:", err);
      throw err;
    }
  }

  // Créer un client simple
  static async createRecord(record) {
    const [result] = await db.execute(
      `INSERT INTO client (numero, compte, parent_id, createur_id) VALUES (?, ?, ?, ?)`,
      [record.numero, record.compte, record.parent_id, record.createur_id]
    );
    return { id: result.insertId, ...record };
  }

  static async getRecordById(id) {
    const [rows] = await db.execute(`SELECT * FROM client WHERE id = ?`, [id]);
    return rows[0] || null;
  }

  // Supprimer un client et toutes les dépendances
  static async deleteRecordById(client_id) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      // Récupérer contact_id
      const [contactRows] = await connection.query(
        `SELECT id FROM contact WHERE client_id = ?`,
        [client_id]
      );
      const contact_id = contactRows.length ? contactRows[0].id : null;

      if (contact_id) {
        await connection.query(`DELETE FROM num_tel WHERE contact_id = ?`, [contact_id]);
        await connection.query(`DELETE FROM adresse_email WHERE contact_id = ?`, [contact_id]);
        await connection.query(`DELETE FROM contact WHERE id = ?`, [contact_id]);
      }

      // Supprimer adresses agence/particulier
      const [agenceRows] = await connection.query(
        `SELECT adresse_id FROM agence WHERE client_id = ?`,
        [client_id]
      );
      if (agenceRows.length) await connection.query(`DELETE FROM adresse WHERE id = ?`, [agenceRows[0].adresse_id]);

      const [partRows] = await connection.query(
        `SELECT adresse_id FROM particulier WHERE client_id = ?`,
        [client_id]
      );
      if (partRows.length) await connection.query(`DELETE FROM adresse WHERE id = ?`, [partRows[0].adresse_id]);

      // Supprimer agences, particuliers, organisations et client
      await connection.query(`DELETE FROM agence WHERE client_id = ?`, [client_id]);
      await connection.query(`DELETE FROM particulier WHERE client_id = ?`, [client_id]);
      await connection.query(`DELETE FROM organisation WHERE client_id = ?`, [client_id]);
      await connection.query(`DELETE FROM client WHERE id = ?`, [client_id]);

      await connection.commit();
      connection.release();
    } catch (err) {
      await connection.rollback();
      connection.release();
      throw err;
    }
  }

  // Détails d’un client avec contacts et type_client
  static async getRecordDetails(id) {
    const [rows] = await db.query(
      `SELECT
      c.id AS client_id,
      c.numero,
      c.compte,
      COALESCE(p.nom_complet, a.nom_agence, o.nom_entreprise) AS nom_client,
      COALESCE(p.note, a.note, o.note) AS note,
      COALESCE(p.id, a.id, o.id) AS id,  -- id spécifique selon le type
      CASE 
        WHEN p.id IS NOT NULL THEN 'particulier'
        WHEN a.id IS NOT NULL THEN 'agence'
        WHEN o.id IS NOT NULL THEN 'organisation'
        ELSE 'inconnu'
      END AS type_client,
      ad.id AS adresseId, ad.adresse AS adresseLigne, ad.code_postal, ad.ville, ad.province, ad.pays,
      ad.etage, ad.appartement_local, ad.batiment, ad.interphone_digicode,
      ad.escalier, ad.porte_entree,
      ct.id AS contact_id, ct.nom_complet AS contact_nom_complet, ct.poste, ct.date_du, ct.date_au, ct.memo_note,
      e.id AS emailId, e.email, e.type AS emailType,
      t.id AS telId, t.tel, t.type AS telType
    FROM client c
    LEFT JOIN particulier p ON p.client_id = c.id
    LEFT JOIN agence a ON a.client_id = c.id
    LEFT JOIN organisation o ON o.client_id = c.id
    LEFT JOIN adresse ad ON ad.id = COALESCE(a.adresse_id, p.adresse_id)
    LEFT JOIN contact ct ON ct.client_id = c.id
    LEFT JOIN adresse_email e ON e.contact_id = ct.id
    LEFT JOIN num_tel t ON t.contact_id = ct.id
    WHERE c.id = ?
    ORDER BY c.id, ct.id`,
      [id]
    );

    if (!rows.length) return null;

    const row = rows[0];

    const client = {
      client_id: row.client_id,   // ID général du client
      id: row.id,                 // ID spécifique selon le type (particulier, agence, organisation)
      type_client: row.type_client,
      numero: row.numero,
      compte: row.compte,
      nom_client: row.nom_client,
      note: row.note,
      adresse: row.adresseId ? {
        id: row.adresseId,
        adresse: row.adresseLigne,
        code_postal: row.code_postal,
        ville: row.ville,
        province: row.province,
        pays: row.pays,
        etage: row.etage,
        appartement_local: row.appartement_local,
        batiment: row.batiment,
        interphone_digicode: row.interphone_digicode,
        escalier: row.escalier,
        porte_entree: row.porte_entree
      } : null,
      contacts: []
    };

    for (const r of rows) {
      if (r.contact_id) {
        let contact = client.contacts.find(ct => ct.id === r.contact_id);
        if (!contact) {
          contact = {
            id: r.contact_id,
            nom_complet: r.contact_nom_complet,
            poste: r.poste,
            date_du: r.date_du,
            date_au: r.date_au,
            memo_note: r.memo_note,
            emails: [],
            telephones: []
          };
          client.contacts.push(contact);
        }

        if (r.emailId && !contact.emails.some(e => e.id === r.emailId))
          contact.emails.push({ id: r.emailId, email: r.email, type: r.emailType });

        if (r.telId && !contact.telephones.some(t => t.id === r.telId))
          contact.telephones.push({ id: r.telId, tel: r.tel, type: r.telType });
      }
    }

    return client;
  }

  static async getInterventionsByClient({
    clientId,
    page = 1,
    limit = 10,
    search = '',
    userId = null
  }) {
    try {
      /* ===================== PAGINATION ===================== */
      page = Number(page);
      limit = Number(limit);

      if (!Number.isInteger(page) || page < 1) page = 1;
      if (!Number.isInteger(limit) || limit < 1) limit = 10;

      const offset = (page - 1) * limit;

      /* ===================== CONDITIONS ===================== */
      let whereClauses = ['i.client_id = ?'];
      let params = [clientId];

      if (userId) {
        whereClauses.push('i.createur_id = ?');
        params.push(userId);
      }

      if (search && search.trim() !== '') {
        whereClauses.push('(i.titre LIKE ? OR i.description LIKE ?)');
        const like = `%${search}%`;
        params.push(like, like);
      }

      const whereSQL = 'WHERE ' + whereClauses.join(' AND ');

      /* ===================== QUERY ===================== */
      const query = `
      SELECT SQL_CALC_FOUND_ROWS
        i.id AS interventionId,
        i.numero AS interventionNumero,
        i.titre AS interventionTitre,
        i.description AS interventionDescription,

        itype.libelle AS interventionType, -- ✅ correction ici

        i.priorite AS interventionPriorite,
        i.etat AS interventionEtat,
        i.date_prevue AS interventionDatePrevue,
        i.date_creation AS interventionDateCreation,

        COALESCE(
          MAX(o.nom_entreprise),
          MAX(ag.nom_agence),
          MAX(p.nom_complet)
        ) AS clientNom,

        CASE
          WHEN MAX(p.client_id) IS NOT NULL THEN 'Particulier'
          WHEN MAX(ag.client_id) IS NOT NULL THEN 'Agence'
          WHEN MAX(o.client_id) IS NOT NULL THEN 'Organisation'
          ELSE 'Inconnu'
        END AS typeClient,

        MAX(h.reference) AS habitation,
        MAX(s.nom) AS secteur,

        GROUP_CONCAT(
          DISTINCT CONCAT(t.nom, ' ', t.prenom)
          SEPARATOR ', '
        ) AS techniciens,

        GROUP_CONCAT(
          DISTINCT CONCAT(r.nom, ' ', r.prenom)
          SEPARATOR ', '
        ) AS referents

      FROM intervention i

      -- ✅ JOIN pour récupérer le libellé du type
      LEFT JOIN intervention_type itype ON itype.id = i.type_id

      INNER JOIN client c ON c.id = i.client_id
      LEFT JOIN particulier p ON p.client_id = c.id
      LEFT JOIN agence ag ON ag.client_id = c.id
      LEFT JOIN organisation o ON o.client_id = c.id
      LEFT JOIN habitation h ON h.id = i.zone_intervention_client_id
      LEFT JOIN secteur s ON s.id = h.secteur_id
      LEFT JOIN intervention_technicien it ON it.id_intervention = i.id
      LEFT JOIN technicien t ON t.id = it.id_technicien
      LEFT JOIN intervention_referent ir ON ir.intervention_id = i.id
      LEFT JOIN referent r ON r.id = ir.referent_id

      ${whereSQL}

      GROUP BY
        i.id,
        i.numero,
        i.titre,
        i.description,
        itype.libelle,
        i.priorite,
        i.etat,
        i.date_prevue,
        i.date_creation

      ORDER BY i.date_creation DESC
      LIMIT ? OFFSET ?;
    `;

      /* ===================== EXECUTION ===================== */
      params.push(limit, offset);

      const [rows] = await db.query(query, params);

      const [[{ total }]] = await db.query(
        'SELECT FOUND_ROWS() AS total'
      );

      return {
        total,
        page,
        limit,
        data: rows
      };

    } catch (err) {
      console.error('Erreur getInterventionsByClient:', err);
      throw err;
    }
  }

  static async getClientsByParentWithDetails({ parentId, parentType, page = 1, limit = 10 }) {
    try {
      page = Number(page);
      limit = Number(limit);
      const offset = (page - 1) * limit;

      /* ================= NORMALISATION TYPE PARENT ================= */
      if (['agence', 'organisation', 'particulier'].includes(parentType)) {
        parentType = 'client';
      }
      if (!['client', 'secteur', 'habitation'].includes(parentType)) {
        throw new Error('parentType invalide');
      }

      /* ================= CONDITIONS PARENT ================= */
      let clientParentCondition = '';
      let secteurParentCondition = '';
      let habitationParentCondition = '';

      switch (parentType) {
        case 'client':
          clientParentCondition = 'c.parent_id = ?';
          secteurParentCondition = 's.parent_id = ? OR s.agence_id = ? OR s.organisation_id = ?';
          habitationParentCondition =
            'h.secteur_id = ? OR h.agence_id = ? OR h.organisation_id = ? OR h.particulier_id = ?';
          break;
        case 'secteur':
          clientParentCondition = '1=0';
          secteurParentCondition = 's.parent_id = ?';
          habitationParentCondition = 'h.secteur_id = ?';
          break;
        case 'habitation':
          clientParentCondition = '1=0';
          secteurParentCondition = '1=0';
          habitationParentCondition = 'h.id = ?';
          break;
      }

      /* ======================= SQL ======================= */
      const query = `
      SELECT * FROM (
        /* ================= CLIENTS ================= */
        SELECT
          c.id AS item_id,
          c.numero,
          c.compte,
          COALESCE(p.nom_complet, a.nom_agence, o.nom_entreprise) AS nom_client,
          NULL AS reference,
          CASE
            WHEN p.id IS NOT NULL THEN 'particulier'
            WHEN a.id IS NOT NULL THEN 'agence'
            WHEN o.id IS NOT NULL THEN 'organisation'
            ELSE 'organisation'
          END AS type_item,
          c.parent_id,
          p.id AS particulier_id,
          a.id AS agence_id,
          o.id AS organisation_id,
          NULL AS secteur_id,
          NULL AS habitation_id,

          /* Adresse */
          COALESCE(adp.id, ada.id) AS adresse_id,
          COALESCE(adp.adresse, ada.adresse) AS adresse,
          COALESCE(adp.code_postal, ada.code_postal) AS code_postal,
          COALESCE(adp.ville, ada.ville) AS ville,
          COALESCE(adp.province, ada.province) AS province,
          COALESCE(adp.pays, ada.pays) AS pays,
          COALESCE(adp.etage, ada.etage) AS etage,
          COALESCE(adp.appartement_local, ada.appartement_local) AS appartement_local,
          COALESCE(adp.batiment, ada.batiment) AS batiment,
          COALESCE(adp.interphone_digicode, ada.interphone_digicode) AS interphone_digicode,
          COALESCE(adp.escalier, ada.escalier) AS escalier,
          COALESCE(adp.porte_entree, ada.porte_entree) AS porte_entree,

          /* Contact du client */
          ct.id AS contact_id,
          ct.nom_complet,
          ct.poste,
          ct.date_du,
          ct.date_au,
          ct.memo_note,
          e.id AS email_id,
          e.email,
          e.type AS email_type,
          t.id AS tel_id,
          t.tel,
          t.type AS tel_type,

          /* Infos du particulier */
          p.nom_complet AS particulier_nom,
          p.email AS particulier_email,
          p.telephone AS particulier_tel

        FROM client c
        LEFT JOIN particulier p ON p.client_id = c.id
        LEFT JOIN agence a ON a.client_id = c.id
        LEFT JOIN organisation o ON o.client_id = c.id
        LEFT JOIN adresse adp ON adp.id = p.adresse_id
        LEFT JOIN adresse ada ON ada.id = a.adresse_id
        LEFT JOIN contact ct ON ct.client_id = c.id
        LEFT JOIN adresse_email e ON e.contact_id = ct.id
        LEFT JOIN num_tel t ON t.contact_id = ct.id
        WHERE ${clientParentCondition}

        UNION ALL

        /* ================= SECTEURS ================= */
        SELECT
          s.id AS item_id,
          NULL,
          NULL,
          s.nom AS nom_client,
          s.reference,
          'secteur' AS type_item,
          s.parent_id,
          NULL,
          s.agence_id,
          s.organisation_id,
          s.id AS secteur_id,
          NULL,
          ad.id AS adresse_id,
          ad.adresse,
          ad.code_postal,
          ad.ville,
          ad.province,
          ad.pays,
          ad.etage,
          ad.appartement_local,
          ad.batiment,
          ad.interphone_digicode,
          ad.escalier,
          ad.porte_entree,
          ct.id AS contact_id,
          ct.nom_complet,
          ct.poste,
          ct.date_du,
          ct.date_au,
          ct.memo_note,
          e.id AS email_id,
          e.email,
          e.type AS email_type,
          t.id AS tel_id,
          t.tel,
          t.type AS tel_type,
          NULL AS particulier_nom,
          NULL AS particulier_email,
          NULL AS particulier_tel
        FROM secteur s
        LEFT JOIN adresse ad ON ad.id = s.adresse_id
        LEFT JOIN contact ct ON ct.secteur_id = s.id
        LEFT JOIN adresse_email e ON e.contact_id = ct.id
        LEFT JOIN num_tel t ON t.contact_id = ct.id
        WHERE ${secteurParentCondition}

        UNION ALL

        /* ================= HABITATIONS ================= */
        SELECT
          h.id AS item_id,
          NULL,
          NULL,
          h.reference AS nom_client,
          h.reference,
          'habitation' AS type_item,
          COALESCE(h.secteur_id, h.agence_id, h.organisation_id, h.particulier_id),
          h.particulier_id,
          h.agence_id,
          h.organisation_id,
          h.secteur_id,
          h.id AS habitation_id,
          ad.id AS adresse_id,
          ad.adresse,
          ad.code_postal,
          ad.ville,
          ad.province,
          ad.pays,
          ad.etage,
          ad.appartement_local,
          ad.batiment,
          ad.interphone_digicode,
          ad.escalier,
          ad.porte_entree,
          ct.id AS contact_id,
          ct.nom_complet,
          ct.poste,
          ct.date_du,
          ct.date_au,
          ct.memo_note,
          e.id AS email_id,
          e.email,
          e.type AS email_type,
          t.id AS tel_id,
          t.tel,
          t.type AS tel_type,
          NULL AS particulier_nom,
          NULL AS particulier_email,
          NULL AS particulier_tel
        FROM habitation h
        LEFT JOIN adresse ad ON ad.id = h.adresse_id
        LEFT JOIN contact ct ON ct.habitation_id = h.id
        LEFT JOIN adresse_email e ON e.contact_id = ct.id
        LEFT JOIN num_tel t ON t.contact_id = ct.id
        WHERE ${habitationParentCondition}

      ) AS full_data
      ORDER BY type_item, item_id
      LIMIT ? OFFSET ?;
    `;

      /* ================= PARAMS ================= */
      const params = [];
      if (parentType === 'client') {
        params.push(parentId);
        params.push(parentId, parentId, parentId);
        params.push(parentId, parentId, parentId, parentId);
      } else if (parentType === 'secteur') {
        params.push(parentId);
        params.push(parentId);
      } else if (parentType === 'habitation') {
        params.push(parentId);
      }
      params.push(limit, offset);

      const [rows] = await db.query(query, params);

      /* ================= FORMATAGE ================= */
      const map = new Map();
      for (const r of rows) {
        if (!map.has(`${r.type_item}_${r.item_id}`)) {
          map.set(`${r.type_item}_${r.item_id}`, {
            id: r.item_id,
            numero: r.numero,
            compte: r.compte,
            nom_client: r.nom_client,
            reference: r.reference,
            type_client: r.type_item,
            parent_id: r.parent_id,
            email: r.particulier_email || r.email || null,
            telephone: r.particulier_tel || r.telephone || null,
            particulier_id: r.particulier_id,
            agence_id: r.agence_id,
            organisation_id: r.organisation_id,
            secteur_id: r.secteur_id,
            habitation_id: r.habitation_id,
            adresse: r.adresse_id
              ? {
                id: r.adresse_id,
                adresse: r.adresse,
                code_postal: r.code_postal,
                ville: r.ville,
                province: r.province,
                pays: r.pays,
                etage: r.etage,
                appartement_local: r.appartement_local,
                batiment: r.batiment,
                interphone_digicode: r.interphone_digicode,
                escalier: r.escalier,
                porte_entree: r.porte_entree
              }
              : null,
            contacts: []
          });
        }

        const item = map.get(`${r.type_item}_${r.item_id}`);

        /* Ajouter le contact et les emails/tel */
        if (r.contact_id) {
          let contact = item.contacts.find(c => c.id === r.contact_id);
          if (!contact) {
            contact = {
              id: r.contact_id,
              nom_complet: r.nom_complet,
              poste: r.poste,
              date_du: r.date_du,
              date_au: r.date_au,
              memo_note: r.memo_note,
              listEmails: [],
              listTels: []
            };
            item.contacts.push(contact);
          }
          if (r.email_id && !contact.listEmails.some(e => e.id === r.email_id)) {
            contact.listEmails.push({ id: r.email_id, email: r.email, type: r.email_type });
          }
          if (r.tel_id && !contact.listTels.some(t => t.id === r.tel_id)) {
            contact.listTels.push({ id: r.tel_id, tel: r.tel, type: r.tel_type });
          }

          /* Ajouter info du particulier */
          if (r.particulier_id) {
            contact.listEmails.push(
              ...(r.particulier_email ? [{ id: r.particulier_id, email: r.particulier_email, type: 'particulier' }] : [])
            );
            contact.listTels.push(
              ...(r.particulier_tel ? [{ id: r.particulier_id, tel: r.particulier_tel, type: 'particulier' }] : [])
            );
            contact.nom_complet_particulier = r.particulier_nom || null;
          }
        }
      }

      return {
        success: true,
        page,
        limit,
        data: Array.from(map.values())
      };

    } catch (error) {
      console.error('Erreur getClientsByParentWithDetails:', error);
      return { success: false, error: error.message };
    }
  }

  static async getAffairesByClient(clientId, page = 1, limit = 10, search = '') {
    try {
      // Validation des paramètres
      const clientIdInt = Number(clientId);
      const pageInt = Number(page);
      const limitInt = Number(limit);

      if (!Number.isInteger(clientIdInt) || !Number.isInteger(pageInt) || !Number.isInteger(limitInt)) {
        throw new Error('clientId, page et limit doivent être des nombres entiers valides');
      }
      if (clientIdInt <= 0 || pageInt <= 0 || limitInt <= 0) {
        throw new Error('clientId, page et limit doivent être positifs');
      }

      const offset = (pageInt - 1) * limitInt;

      // Construction du WHERE
      let whereClause = 'WHERE a.client_id = ?';
      const params = [clientIdInt];

      if (search && search.trim() !== '') {
        whereClause += ' AND (a.titre LIKE ? OR a.reference LIKE ?)';
        params.push(`%${search}%`, `%${search}%`);
      }

      // Requête principale — LIMIT et OFFSET injectés directement dans la query
      const query = `
      SELECT 
        a.id AS affaireId,
        a.reference,
        a.titre AS affaireTitre,
        a.description AS affaireDescription,
        a.etatLogement,
        a.dateDebut,
        a.dateFin,
        a.motsCles,
        a.dureePrevueHeures,
        a.dureePrevueMinutes
      FROM affaire a
      ${whereClause}
      ORDER BY a.dateDebut DESC
      LIMIT ${limitInt} OFFSET ${offset}
    `;

      const [rows] = await db.execute(query, params);

      // Requête pour total (pas de LIMIT/OFFSET)
      const countQuery = `
      SELECT COUNT(*) AS total
      FROM affaire a
      ${whereClause}
    `;
      const [countRows] = await db.execute(countQuery, params);

      return {
        total: countRows[0].total,
        page: pageInt,
        limit: limitInt,
        affaires: rows
      };

    } catch (error) {
      console.error('Erreur getAffairesByClient:', error);
      throw error;
    }
  }

}

module.exports = ClientService;
