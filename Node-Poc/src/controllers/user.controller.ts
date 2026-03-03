import { Response } from "express";
import bcrypt from "bcryptjs";
import { UserModel } from "../models/user.model";
import { AuthRequest } from "../middleware/auth.middleware";

const SALT_ROUNDS = 10;

/**
 * GET /api/users
 * Get all users (protected)
 */
export const getAllUsers = (_req: AuthRequest, res: Response): void => {
  const users = UserModel.findAll();
  res.status(200).json({ users });
};

/**
 * GET /api/users/:id
 * Get a single user by ID (protected)
 */
export const getUserById = (req: AuthRequest, res: Response): void => {
  const id = req.params.id as string;
  const user = UserModel.findById(id);
  if (!user) {
    res.status(404).json({ message: "User not found" });
    return;
  }

  const { password, ...userPublic } = user;
  res.status(200).json({ user: userPublic });
};

/**
 * PUT /api/users/:id
 * Update a user (protected — only own account)
 */
export const updateUser = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const id = req.params.id as string;

    // Users can only update their own account
    if (req.userId !== id) {
      res
        .status(403)
        .json({ message: "Forbidden: you can only update your own account" });
      return;
    }

    const existingUser = UserModel.findById(id);
    if (!existingUser) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    const { username, email, password } = req.body;
    const updateData: Partial<{ username: string; email: string; password: string }> = {};

    if (username) {
      const taken = UserModel.findByUsername(username);
      if (taken && taken.id !== id) {
        res.status(409).json({ message: "Username already taken" });
        return;
      }
      updateData.username = username;
    }

    if (email) {
      const taken = UserModel.findByEmail(email);
      if (taken && taken.id !== id) {
        res.status(409).json({ message: "Email already in use" });
        return;
      }
      updateData.email = email;
    }

    if (password) {
      if (password.length < 6) {
        res
          .status(400)
          .json({ message: "Password must be at least 6 characters" });
        return;
      }
      updateData.password = await bcrypt.hash(password, SALT_ROUNDS);
    }

    const updated = UserModel.update(id, updateData);
    if (!updated) {
      res.status(500).json({ message: "Failed to update user" });
      return;
    }

    const { password: _, ...userPublic } = updated;
    res.status(200).json({ message: "User updated successfully", user: userPublic });
  } catch (error) {
    res.status(500).json({ message: "Internal server error" });
  }
};

/**
 * DELETE /api/users/:id
 * Delete a user (protected — only own account)
 */
export const deleteUser = (req: AuthRequest, res: Response): void => {
  const id = req.params.id as string;

  if (req.userId !== id) {
    res
      .status(403)
      .json({ message: "Forbidden: you can only delete your own account" });
    return;
  }

  const deleted = UserModel.delete(id);
  if (!deleted) {
    res.status(404).json({ message: "User not found" });
    return;
  }

  res.status(200).json({ message: "User deleted successfully" });
};
