const { Router } = require('express');
const { body } = require('express-validator');
const { login, getProfile } = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = Router();

router.post('/login', [
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required')
], validate, login);

router.get('/profile', authenticate, getProfile);

module.exports = router;
