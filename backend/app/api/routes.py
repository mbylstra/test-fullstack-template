from fastapi import APIRouter

from app.routers import auth, todos, weighted_random_todos, habits, funs, weighted_random_funs, note

router = APIRouter()

router.include_router(auth.router)
router.include_router(todos.router)
router.include_router(habits.router)
router.include_router(funs.router)
router.include_router(note.router)
router.include_router(weighted_random_todos.router)
router.include_router(weighted_random_funs.router)
