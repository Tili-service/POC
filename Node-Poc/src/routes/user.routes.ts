import { Router } from "express";
import {
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
} from "../controllers/user.controller";
import { authMiddleware } from "../middleware/auth.middleware";

const router = Router();

// All user routes are protected
router.use(authMiddleware);

router.get("/", getAllUsers);
router.get("/:id", getUserById);
router.put("/:id", updateUser);
router.delete("/:id", deleteUser);

export default router;
