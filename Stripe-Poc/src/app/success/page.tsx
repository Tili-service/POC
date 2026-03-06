'use client'
import { useSearchParams } from 'next/navigation'

export default function SuccessPage() {
    const params = useSearchParams();
    console.log(params.get("session_id"))
    return (
        <div className="min-h-screen flex items-center justify-center bg-background">
            <div className="text-center">
                <h1 className="text-3xl font-bold mb-4">Paiement réussi !</h1>
                <p className="text-muted-foreground">Session ID: {params.get("session_id")}</p>
                <p className="text-muted-foreground">Votre commande a été traitée avec succès.</p>
            </div>
        </div>
    );
}