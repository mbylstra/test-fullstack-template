import FunList from '@/components/FunList';
import { useFuns } from '@/hooks/useFuns';

export default function Fun() {
    const { funs, loading, addFun, updateFun, deleteFun, reorderFuns } =
        useFuns();

    if (loading) {
        return (
            <div className="flex items-center justify-center h-screen">
                <div className="text-gray-500">Loading...</div>
            </div>
        );
    }

    const handleAddFun = async (
        title: string,
        position: 'top' | 'bottom'
    ): Promise<void> => {
        await addFun(title, position);
    };

    return (
        <div className="container mx-auto py-8">
            <h1 className="text-3xl font-bold mb-8 text-center">Fun Things</h1>
            <FunList
                funs={funs}
                onAddFun={handleAddFun}
                onUpdateFun={updateFun}
                onDeleteFun={deleteFun}
                onReorderFuns={reorderFuns}
            />
        </div>
    );
}
