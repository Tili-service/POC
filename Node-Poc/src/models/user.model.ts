import { v4 as uuidv4 } from "uuid";

export interface User {
  id: string;
  username: string;
  email: string;
  password: string; // hashed
  createdAt: Date;
  updatedAt: Date;
}

export type UserPublic = Omit<User, "password">;

// In-memory store
const users: Map<string, User> = new Map();

export const UserModel = {
  findAll(): UserPublic[] {
    return Array.from(users.values()).map(({ password, ...rest }) => rest);
  },

  findById(id: string): User | undefined {
    return users.get(id);
  },

  findByEmail(email: string): User | undefined {
    return Array.from(users.values()).find((u) => u.email === email);
  },

  findByUsername(username: string): User | undefined {
    return Array.from(users.values()).find((u) => u.username === username);
  },

  create(data: { username: string; email: string; password: string }): User {
    const now = new Date();
    const user: User = {
      id: uuidv4(),
      username: data.username,
      email: data.email,
      password: data.password,
      createdAt: now,
      updatedAt: now,
    };
    users.set(user.id, user);
    return user;
  },

  update(
    id: string,
    data: Partial<Pick<User, "username" | "email" | "password">>
  ): User | undefined {
    const user = users.get(id);
    if (!user) return undefined;

    const updated: User = {
      ...user,
      ...data,
      updatedAt: new Date(),
    };
    users.set(id, updated);
    return updated;
  },

  delete(id: string): boolean {
    return users.delete(id);
  },
};
