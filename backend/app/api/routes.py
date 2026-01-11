from fastapi import APIRouter

from app.routers import auth, note

router = APIRouter()

router.include_router(auth.router)
router.include_router(note.router)
