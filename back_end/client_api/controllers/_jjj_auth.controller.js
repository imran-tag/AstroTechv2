// auth.controller.js
const pool = require('../db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const dotenv = require('dotenv');
import crypto from 'crypto';
import nodemailer from 'nodemailer';
dotenv.config();

const SALT_ROUNDS = 10;

async function register(req, res) {
  try {
    const { email, password, full_name } = req.body;
    if (!email || !password) return res.status(400).json({ message: 'Email et mot de passe requis' });

    const [rows] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (rows.length) return res.status(409).json({ message: 'Email déjà utilisé' });

    const hash = await bcrypt.hash(password, SALT_ROUNDS);
    const [result] = await pool.query(
      'INSERT INTO users (email, password_hash, full_name) VALUES (?, ?, ?)',
      [email, hash, full_name || null]
    );

    const userId = result.insertId;
    const token = jwt.sign({ id: userId, email }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });
    res.status(201).json({ token, user: { id: userId, email, full_name } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ message: 'Email et mot de passe requis' });

    const [rows] = await pool.query('SELECT id, password_hash, full_name FROM users WHERE email = ?', [email]);
    if (!rows.length) return res.status(401).json({ message: 'Identifiants incorrects' });

    const user = rows[0];
    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) return res.status(401).json({ message: 'Identifiants incorrects' });

    const token = jwt.sign({ id: user.id, email }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });
    res.json({ token, user: { id: user.id, email, full_name: user.full_name } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
}

async function me(req, res) {
  try {
    const userId = req.user.id;
    const [rows] = await pool.query('SELECT id, email, full_name, role, date_creation FROM users WHERE id = ?', [userId]);
    if (!rows.length) return res.status(404).json({ message: 'Utilisateur introuvable' });
    res.json({ user: rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
}

// ... (tes imports et fonctions existantes)

async function updateProfile(req, res) {
  try {
    const userId = req.user.id; // Récupéré via ton middleware d'authentification
    const { full_name, email } = req.body;

    if (!full_name && !email) {
      return res.status(400).json({ message: 'Aucune donnée à mettre à jour' });
    }

    // Mise à jour dynamique selon ce qui est envoyé
    await pool.query(
      'UPDATE users SET full_name = COALESCE(?, full_name), email = COALESCE(?, email) WHERE id = ?',
      [full_name, email, userId]
    );

    res.json({ message: 'Profil mis à jour avec succès' });
  } catch (err) {
    console.error(err);
    // Gestion de l'erreur si l'email est déjà pris par un autre utilisateur
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'Cet email est déjà utilisé' });
    }
    res.status(500).json({ message: 'Erreur serveur' });
  }
}

async function updatePassword(req, res) {
  try {
    const userId = req.user.id;
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      return res.status(400).json({ message: 'Ancien et nouveau mot de passe requis' });
    }

    // 1. Vérifier l'ancien mot de passe
    const [rows] = await pool.query('SELECT password_hash FROM users WHERE id = ?', [userId]);
    const user = rows[0];

    const isMatch = await bcrypt.compare(oldPassword, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ message: 'Ancien mot de passe incorrect' });
    }

    // 2. Hasher le nouveau mot de passe et sauvegarder
    const newHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await pool.query('UPDATE users SET password_hash = ? WHERE id = ?', [newHash, userId]);

    res.json({ message: 'Mot de passe modifié avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
}

// async function forgotPassword(req, res) {
//   try {
//     const { email } = req.body;

//     // 1. Vérifier si l'utilisateur existe
//     const [rows] = await pool.query('SELECT id, full_name FROM users WHERE email = ?', [email]);
//     if (rows.length === 0) {
//       // Sécurité : on ne confirme pas que l'email n'existe pas
//       return res.json({ message: 'Si cet email existe, un lien de réinitialisation a été envoyé.' });
//     }

//     const user = rows[0];

//     // 2. Créer un token et une expiration
//     const token = crypto.randomBytes(32).toString('hex');
//     const expires = new Date(Date.now() + 3600000); // 1 heure

//     // 3. Sauvegarder le token dans la table 'users'
//     // (Assure-toi d'avoir ajouté les colonnes reset_token et reset_expires via SQL)
//     await pool.query(
//       'UPDATE users SET reset_token = ?, reset_expires = ? WHERE id = ?',
//       [token, expires, user.id]
//     );

//     // 4. Envoyer l'email
//     const transporter = nodemailer.createTransport({
//       service: 'gmail', // ou ton SMTP
//       auth: { user: 'sennan.zineb@gmail.com', pass: 'ton-mot-de-passe' }
//     });

//     const resetLink = `http://ton-site.com/reset-password/${token}`;

//     await transporter.sendMail({
//       from: '"Admin System" <noreply@votre-app.com>',
//       to: email,
//       subject: 'Réinitialisation de votre mot de passe',
//       html: `<p>Bonjour ${user.full_name},</p>
//              <p>Cliquez sur ce lien pour réinitialiser votre mot de passe : <a href="${resetLink}">Changer mon mot de passe</a></p>`
//     });

//     res.json({ message: 'Si cet email existe, un lien de réinitialisation a été envoyé.' });

//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ message: 'Erreur serveur' });
//   }
// }

// N'oublie pas de mettre à jour les exports à la fin du fichier
module.exports = { register, login, me, updateProfile, updatePassword };