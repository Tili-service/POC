import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { UserModel } from "../models/user.model";
import { config } from "../config";
import { AuthRequest } from "../middleware/auth.middleware";

const SALT_ROUNDS = 10;

/**
 * POST /api/auth/register
 * Register a new user
 */
export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const { username, email, password } = req.body;

    // Validation
    if (!username || !email || !password) {
      res
        .status(400)
        .json({ message: "Username, email, and password are required" });
      return;
    }

    if (password.length < 6) {
      res
        .status(400)
        .json({ message: "Password must be at least 6 characters" });
      return;
    }

    // Check if user already exists
    if (UserModel.findByEmail(email)) {
      res.status(409).json({ message: "Email already in use" });
      return;
    }

    if (UserModel.findByUsername(username)) {
      res.status(409).json({ message: "Username already taken" });
      return;
    }

    // Hash password and create user
    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
    const user = UserModel.create({
      username,
      email,
      password: hashedPassword,
    });

    // Generate token
    const token = jwt.sign({ userId: user.id }, config.jwtSecret, {
      expiresIn: config.jwtExpiresIn,
    });

    const { password: _, ...userPublic } = user;

    res.status(201).json({
      message: "User registered successfully",
      user: userPublic,
      token,
    });
  } catch (error) {
    res.status(500).json({ message: "Internal server error" });
  }
};

/**
 * POST /api/auth/login
 * Login with email and password
 */
export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      res.status(400).json({ message: "Email and password are required" });
      return;
    }

    const user = UserModel.findByEmail(email);
    if (!user) {
      res.status(401).json({ message: "Invalid credentials" });
      return;
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      res.status(401).json({ message: "Invalid credentials" });
      return;
    }

    const token = jwt.sign({ userId: user.id }, config.jwtSecret, {
      expiresIn: config.jwtExpiresIn,
    });

    const { password: _, ...userPublic } = user;

    res.status(200).json({
      message: "Login successful",
      user: userPublic,
      token,
    });
  } catch (error) {
    res.status(500).json({ message: "Internal server error" });
  }
};

/**
 * GET /api/auth/me
 * Get current authenticated user profile
 */
export const getMe = (req: AuthRequest, res: Response): void => {
  const user = UserModel.findById(req.userId!);
  if (!user) {
    res.status(404).json({ message: "User not found" });
    return;
  }

  const { password, ...userPublic } = user;
  res.status(200).json({ user: userPublic });
};
