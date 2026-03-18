from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
import logging

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Sync API POC", version="1.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class User(BaseModel):
    id: int
    name: str
    email: EmailStr
    age: int
    bio: str | None = None


userList: list[User] = [
    User(
        id=1,
        name="Leanne Graham",
        email="Sincere@april.biz",
        age=30,
        bio="Un petit texte de présentation"
    ),
]


@app.get("/")
def root():
    """Health check"""
    return {"status": "ok", "users_count": len(userList)}


@app.get("/users")
def read_root():
    """Récupère tous les utilisateurs"""
    logger.info(f"GET /users - Retour {len(userList)} utilisateurs")
    return userList


@app.post("/users")
def create_user(user: User):
    """Crée un nouvel utilisateur"""
    # Vérifier si l'ID existe déjà
    if any(u.id == user.id for u in userList):
        logger.warning(f"POST /users - ID {user.id} existe déjà")
        raise HTTPException(status_code=400, detail="ID utilisateur existe déjà")
    userList.append(user)
    logger.info(f"POST /users - Créé utilisateur ID {user.id}")
    return user


@app.get("/users/{user_id}")
def get_user(user_id: int):
    """Récupère un utilisateur par ID"""
    for user in userList:
        if user.id == user_id:
            return user
    logger.warning(f"GET /users/{user_id} - Pas trouvé")
    raise HTTPException(status_code=404, detail="Utilisateur non trouvé")


@app.put("/users/{user_id}")
def update_user(user_id: int, user: User):
    """Met à jour un utilisateur"""
    for i, existing_user in enumerate(userList):
        if existing_user.id == user_id:
            # Vérifier que l'ID dans le payload correspond
            if user.id != user_id:
                logger.warning(f"PUT /users/{user_id} - ID mismatch")
                raise HTTPException(status_code=400, detail="ID mismatch")
            userList[i] = user
            logger.info(f"PUT /users/{user_id} - Mis à jour")
            return user
    logger.warning(f"PUT /users/{user_id} - Pas trouvé")
    raise HTTPException(status_code=404, detail="Utilisateur non trouvé")


@app.delete("/users/{user_id}")
def delete_user(user_id: int):
    """Supprime un utilisateur"""
    for i, user in enumerate(userList):
        if user.id == user_id:
            deleted_user = userList.pop(i)
            logger.info(f"DELETE /users/{user_id} - Supprimé")
            return {"message": "Utilisateur supprimé", "user": deleted_user}
    logger.warning(f"DELETE /users/{user_id} - Pas trouvé")
    raise HTTPException(status_code=404, detail="Utilisateur non trouvé")

