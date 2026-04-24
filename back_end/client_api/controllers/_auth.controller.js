const pool = require('../db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const nodemailer = require('nodemailer');
const crypto = require('crypto');

const SALT_ROUNDS = 10;

// ================= REGISTER =================
async function register(req, res) {
  try {
    const { email, password, full_name } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email et mot de passe requis' });
    }

    const [rows] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (rows.length) {
      return res.status(409).json({ message: 'Email déjà utilisé' });
    }

    const hash = await bcrypt.hash(password, SALT_ROUNDS);

    const [result] = await pool.query(
      'INSERT INTO users (email, password_hash, full_name) VALUES (?, ?, ?)',
      [email, hash, full_name || null]
    );

    const token = jwt.sign(
      { id: result.insertId, email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    res.status(201).json({
      token,
      user: { id: result.insertId, email, full_name }
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
}

// ================= LOGIN =================
async function login(req, res) {
  try {
    const { email, password } = req.body;

    const [rows] = await pool.query(
      'SELECT id, password_hash, full_name FROM users WHERE email = ?',
      [email]
    );

    if (!rows.length) {
      return res.status(401).json({ message: 'Identifiants incorrects' });
    }

    const user = rows[0];
    const match = await bcrypt.compare(password, user.password_hash);

    if (!match) {
      return res.status(401).json({ message: 'Identifiants incorrects' });
    }

    const token = jwt.sign(
      { id: user.id, email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    res.json({
      token,
      user: { id: user.id, email, full_name: user.full_name }
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
}

// ================= ME =================
async function me(req, res) {
  try {
    const [rows] = await pool.query(
      'SELECT id, email, full_name, role, date_creation FROM users WHERE id = ?',
      [req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ message: 'Utilisateur introuvable' });
    }

    res.json({ user: rows[0] });

  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
}

// ================= UPDATE PROFILE =================
async function updateProfile(req, res) {
  try {
    const { full_name, email } = req.body;

    if (!full_name && !email) {
      return res.status(400).json({ message: 'Aucune donnée à mettre à jour' });
    }

    await pool.query(
      'UPDATE users SET full_name = COALESCE(?, full_name), email = COALESCE(?, email) WHERE id = ?',
      [full_name, email, req.user.id]
    );

    res.json({ message: 'Profil mis à jour' });

  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'Email déjà utilisé' });
    }
    res.status(500).json({ message: 'Erreur serveur' });
  }
}

// ================= UPDATE PASSWORD =================
async function updatePassword(req, res) {
  try {
    const { oldPassword, newPassword } = req.body;

    const [rows] = await pool.query(
      'SELECT password_hash FROM users WHERE id = ?',
      [req.user.id]
    );

    const user = rows[0];
    const match = await bcrypt.compare(oldPassword, user.password_hash);

    if (!match) {
      return res.status(401).json({ message: 'Ancien mot de passe incorrect' });
    }

    const newHash = await bcrypt.hash(newPassword, SALT_ROUNDS);

    await pool.query(
      'UPDATE users SET password_hash = ? WHERE id = ?',
      [newHash, req.user.id]
    );

    res.json({ message: 'Mot de passe modifié' });

  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
}

// ================= FORGOT PASSWORD =================

// const transporter = nodemailer.createTransport({
//   host: process.env.EMAIL_HOST,
//   port: parseInt(process.env.EMAIL_PORT),
//   secure: false,
//   auth: {
//     user: process.env.EMAIL_USER,
//     pass: process.env.EMAIL_PASS,
//   },
// });


const transporter = nodemailer.createTransport({
  host: 'smtp.ethereal.email',
  port: 587,
  auth: {
    user: 'sabrina.jacobs@ethereal.email',
    pass: 'KX2vFARTwTMJDv3BPF'
  }
});


async function forgotPassword(req, res) {
  try {
    console.log("--- Début de la procédure forgotPassword ---");
    const { email } = req.body;

    // 1. DB Check
    const [rows] = await pool.query('SELECT id, full_name FROM users WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.json({ message: 'Si cet email existe, un lien a été envoyé' });
    }

    const user = rows[0];
    const token = crypto.randomBytes(32).toString('hex');
    const expires = new Date(Date.now() + 3600000);

    await pool.query(
      'UPDATE users SET reset_token = ?, reset_expires = ? WHERE id = ?',
      [token, expires, user.id]
    );

    const resetLink = `${process.env.FRONTEND_URL}/reset-password/${token}`;

    // 2. Envoi Direct
    const info = await transporter.sendMail({
      from: `"AstroTech Support" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Réinitialisation de mot de passe',
      html: `<p>Bonjour ${user.full_name}, cliquez ici : <a href="${resetLink}">Lien</a></p>`
    });

    console.log('✅ Email envoyé :', nodemailer.getTestMessageUrl(info));
    return res.json({ message: 'Email envoyé', preview: nodemailer.getTestMessageUrl(info) });

  } catch (err) {
    console.error("❌ Erreur dans forgotPassword :", err.message);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
}


async function resetPassword(req, res) {
  try {
    const { token } = req.params;
    const { password } = req.body;

    if (!password || password.length < 6) {
      return res.status(400).json({ message: "Le mot de passe doit contenir au moins 6 caractères." });
    }

    // Vérification du token
    const [rows] = await pool.query(
      'SELECT id FROM users WHERE reset_token = ? AND reset_expires > NOW()',
      [token]
    );

    if (rows.length === 0) {
      return res.status(400).json({ message: 'Le lien est invalide ou a expiré.' });
    }

    const userId = rows[0].id;
    const hashedPassword = await bcrypt.hash(password, 10);

    // ✅ Correction ici : utiliser 'password_hash' au lieu de 'password'
    await pool.query(
      'UPDATE users SET password_hash = ?, reset_token = NULL, reset_expires = NULL WHERE id = ?',
      [hashedPassword, userId]
    );

    console.log(`✅ Mot de passe mis à jour pour l'utilisateur ID: ${userId}`);

    return res.json({
      message: 'Votre mot de passe a été modifié avec succès.'
    });

  } catch (err) {
    console.error("❌ Erreur resetPassword :", err.message);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
}

module.exports = {
  register,
  login,
  me,
  updateProfile,
  updatePassword,
  forgotPassword,
  resetPassword
};