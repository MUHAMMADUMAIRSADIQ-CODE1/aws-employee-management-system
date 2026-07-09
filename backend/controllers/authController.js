const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');
const { sendSuccess, sendError } = require('../utils/response');
const { logger } = require('../utils/logger');
const { BCRYPT_SALT_ROUNDS } = require('../config/constants');

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const [rows] = await pool.execute(
      'SELECT id, name, email, password FROM admins WHERE email = ?',
      [email]
    );

    if (rows.length === 0) {
      return sendError(res, 'Invalid email or password.', 401);
    }

    const admin = rows[0];
    const isMatch = await bcrypt.compare(password, admin.password);

    if (!isMatch) {
      return sendError(res, 'Invalid email or password.', 401);
    }

    const token = jwt.sign(
      { id: admin.id, email: admin.email, name: admin.name },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    logger.info(`Admin ${admin.email} logged in successfully`);

    return sendSuccess(res, {
      token,
      admin: {
        id: admin.id,
        name: admin.name,
        email: admin.email
      }
    }, 'Login successful');
  } catch (error) {
    next(error);
  }
};

const getProfile = async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, name, email, createdAt FROM admins WHERE id = ?',
      [req.admin.id]
    );

    if (rows.length === 0) {
      return sendError(res, 'Admin not found.', 404);
    }

    return sendSuccess(res, { admin: rows[0] });
  } catch (error) {
    next(error);
  }
};

const seedAdmin = async () => {
  try {
    const [rows] = await pool.execute(
      'SELECT id FROM admins WHERE email = ?',
      [process.env.ADMIN_EMAIL || 'admin@example.com']
    );

    if (rows.length === 0) {
      const hashedPassword = await bcrypt.hash(
        process.env.ADMIN_PASSWORD || 'Admin@123',
        BCRYPT_SALT_ROUNDS
      );

      await pool.execute(
        'INSERT INTO admins (name, email, password) VALUES (?, ?, ?)',
        [
          process.env.ADMIN_NAME || 'Super Admin',
          process.env.ADMIN_EMAIL || 'admin@example.com',
          hashedPassword
        ]
      );

      logger.info('Default admin account created');
    }
  } catch (error) {
    logger.error('Failed to seed admin:', error);
  }
};

module.exports = { login, getProfile, seedAdmin };
