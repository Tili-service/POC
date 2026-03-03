import express from "express";
import { config } from "./config";
import authRoutes from "./routes/auth.routes";
import userRoutes from "./routes/user.routes";

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);

// Health check
app.get("/health", (_req, res) => {
  res.status(200).json({ status: "ok", timestamp: new Date().toISOString() });
});

// Start server
app.listen(config.port, () => {
  console.log(`🚀 Server running on http://localhost:${config.port}`);
  console.log(`📋 API Endpoints:`);
  console.log(`   POST   /api/auth/register  - Register a new user`);
  console.log(`   POST   /api/auth/login     - Login`);
  console.log(`   GET    /api/auth/me        - Get current user (auth)`);
  console.log(`   GET    /api/users           - List all users (auth)`);
  console.log(`   GET    /api/users/:id       - Get user by ID (auth)`);
  console.log(`   PUT    /api/users/:id       - Update user (auth)`);
  console.log(`   DELETE /api/users/:id       - Delete user (auth)`);
});

export default app;
