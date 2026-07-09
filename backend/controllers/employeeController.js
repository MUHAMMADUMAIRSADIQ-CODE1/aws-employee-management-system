const { pool } = require('../config/database');
const { sendSuccess, sendError, sendPaginated } = require('../utils/response');
const { logger } = require('../utils/logger');
const { DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE } = require('../config/constants');

const getAll = async (req, res, next) => {
  try {
    let { page = 1, limit = DEFAULT_PAGE_SIZE, search, status, department } = req.query;

    page = Math.max(1, parseInt(page, 10) || 1);
    limit = Math.min(MAX_PAGE_SIZE, Math.max(1, parseInt(limit, 10) || DEFAULT_PAGE_SIZE));
    const offset = (page - 1) * limit;

    let whereClause = [];
    let params = [];

    if (search) {
      whereClause.push('(firstName LIKE ? OR lastName LIKE ? OR email LIKE ? OR phone LIKE ?)');
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm, searchTerm, searchTerm);
    }

    if (status) {
      whereClause.push('status = ?');
      params.push(status);
    }

    if (department) {
      whereClause.push('department = ?');
      params.push(department);
    }

    const whereSQL = whereClause.length > 0 ? `WHERE ${whereClause.join(' AND ')}` : '';

    const [countResult] = await pool.execute(
      `SELECT COUNT(*) as total FROM employees ${whereSQL}`,
      params
    );
    const total = countResult[0].total;

    const [rows] = await pool.execute(
      `SELECT * FROM employees ${whereSQL} ORDER BY createdAt DESC LIMIT ? OFFSET ?`,
      [...params, String(limit), String(offset)]
    );

    return sendPaginated(res, rows, total, page, limit);
  } catch (error) {
    next(error);
  }
};

const getById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.execute(
      'SELECT * FROM employees WHERE id = ?',
      [id]
    );

    if (rows.length === 0) {
      return sendError(res, 'Employee not found.', 404);
    }

    return sendSuccess(res, { employee: rows[0] });
  } catch (error) {
    next(error);
  }
};

const create = async (req, res, next) => {
  try {
    const { firstName, lastName, email, phone, department, position, salary, address, hireDate, status } = req.body;

    const [result] = await pool.execute(
      `INSERT INTO employees (firstName, lastName, email, phone, department, position, salary, address, hireDate, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [firstName, lastName, email, phone || null, department || null, position || null, salary || null, address || null, hireDate || null, status || 'active']
    );

    const [employee] = await pool.execute(
      'SELECT * FROM employees WHERE id = ?',
      [result.insertId]
    );

    logger.info(`Employee created: ${firstName} ${lastName} (ID: ${result.insertId})`);

    return sendSuccess(res, { employee: employee[0] }, 'Employee created successfully', 201);
  } catch (error) {
    next(error);
  }
};

const update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { firstName, lastName, email, phone, department, position, salary, address, hireDate, status } = req.body;

    const [existing] = await pool.execute(
      'SELECT id FROM employees WHERE id = ?',
      [id]
    );

    if (existing.length === 0) {
      return sendError(res, 'Employee not found.', 404);
    }

    await pool.execute(
      `UPDATE employees SET
        firstName = ?, lastName = ?, email = ?, phone = ?,
        department = ?, position = ?, salary = ?,
        address = ?, hireDate = ?, status = ?
       WHERE id = ?`,
      [firstName, lastName, email, phone || null, department || null, position || null, salary || null, address || null, hireDate || null, status || 'active', id]
    );

    const [updated] = await pool.execute(
      'SELECT * FROM employees WHERE id = ?',
      [id]
    );

    logger.info(`Employee updated: ID ${id}`);

    return sendSuccess(res, { employee: updated[0] }, 'Employee updated successfully');
  } catch (error) {
    next(error);
  }
};

const remove = async (req, res, next) => {
  try {
    const { id } = req.params;

    const [existing] = await pool.execute(
      'SELECT id, firstName, lastName FROM employees WHERE id = ?',
      [id]
    );

    if (existing.length === 0) {
      return sendError(res, 'Employee not found.', 404);
    }

    await pool.execute('DELETE FROM employees WHERE id = ?', [id]);

    logger.info(`Employee deleted: ${existing[0].firstName} ${existing[0].lastName} (ID: ${id})`);

    return sendSuccess(res, null, 'Employee deleted successfully');
  } catch (error) {
    next(error);
  }
};

const getDepartments = async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      'SELECT DISTINCT department FROM employees WHERE department IS NOT NULL ORDER BY department'
    );
    const departments = rows.map(r => r.department);
    return sendSuccess(res, { departments });
  } catch (error) {
    next(error);
  }
};

const getStats = async (req, res, next) => {
  try {
    const [total] = await pool.execute('SELECT COUNT(*) as count FROM employees');
    const [active] = await pool.execute("SELECT COUNT(*) as count FROM employees WHERE status = 'active'");
    const [inactive] = await pool.execute("SELECT COUNT(*) as count FROM employees WHERE status = 'inactive'");
    const [departments] = await pool.execute('SELECT COUNT(DISTINCT department) as count FROM employees WHERE department IS NOT NULL');

    return sendSuccess(res, {
      stats: {
        total: total[0].count,
        active: active[0].count,
        inactive: inactive[0].count,
        departments: departments[0].count
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { getAll, getById, create, update, remove, getDepartments, getStats };
