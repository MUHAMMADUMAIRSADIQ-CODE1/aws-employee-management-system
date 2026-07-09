const { Router } = require('express');
const { body } = require('express-validator');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const {
  getAll, getById, create, update, remove, getDepartments, getStats
} = require('../controllers/employeeController');

const router = Router();

router.use(authenticate);

const employeeValidation = [
  body('firstName').trim().notEmpty().withMessage('First name is required')
    .isLength({ max: 50 }).withMessage('First name must be at most 50 characters'),
  body('lastName').trim().notEmpty().withMessage('Last name is required')
    .isLength({ max: 50 }).withMessage('Last name must be at most 50 characters'),
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('phone').optional({ values: 'falsy' }).trim(),
  body('department').optional({ values: 'falsy' }).trim().isLength({ max: 100 }),
  body('position').optional({ values: 'falsy' }).trim().isLength({ max: 100 }),
  body('salary').optional({ values: 'falsy' }).isFloat({ min: 0 }).withMessage('Salary must be a positive number'),
  body('address').optional({ values: 'falsy' }).trim(),
  body('hireDate').optional({ values: 'falsy' }).isDate().withMessage('Invalid date format'),
  body('status').optional().isIn(['active', 'inactive', 'terminated']).withMessage('Invalid status')
];

router.get('/', getAll);
router.get('/stats', getStats);
router.get('/departments', getDepartments);
router.get('/:id', getById);
router.post('/', employeeValidation, validate, create);
router.put('/:id', employeeValidation, validate, update);
router.delete('/:id', remove);

module.exports = router;
