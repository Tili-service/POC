import { NextRequest, NextResponse } from "next/server";
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY as string);

const createCustomer = async (email: string, name: string) => {
  const params: Stripe.CustomerCreateParams = {
    email: email,
    name: name,
  };
  const customer: Stripe.Customer = await stripe.customers.create(params);
  return customer.id;
};

export async function POST(request: NextRequest) {
    try {
        const formData = await request.formData();
        const origin = request.headers.get("origin") || "http://localhost:3000";
        const email = formData.get("email") as string;
        const firstName = formData.get("firstName") as string;
        const lastName = formData.get("lastName") as string;
        const shopName = formData.get("shopName") as string;
        const offer = formData.get("offer") as string;

        if (!email || !firstName || !lastName || !shopName || !offer) {
            return NextResponse.json({ error: "Champs manquants" }, { status: 400 });
        }

        const STRIPE_PRICES: Record<string, string> = {
            "mensuel": process.env.STRIPE_MENSUAL_PRICE as string,
            "semestriel": process.env.STRIPE_SEMESTRAL_PRICE as string,
            "annuel": process.env.STRIPE_ANNUAL_PRICE as string,
        };

        const priceId = STRIPE_PRICES[offer];

        if (!priceId) {
            return NextResponse.json({ error: "Offre invalide" }, { status: 400 });
        }

        const productId = STRIPE_PRICES[offer];
        console.log("ID du produit sélectionné :", productId);

        const customerId = await createCustomer(email, `${firstName} ${lastName}`);

        const session = await stripe.checkout.sessions.create({
            customer: customerId,
            payment_method_types: ['card'],
            mode: 'subscription',
            line_items: [
                {
                    price: priceId,
                    quantity: 1,
                },
            ],
            success_url: `${origin}/success?session_id={CHECKOUT_SESSION_ID}`,
            cancel_url: `${origin}/?error=canceled`,
        });
        return NextResponse.redirect(session.url!, 303);
    } catch (error: any) {
        console.error("Erreur Stripe :", error);
        const origin = request.headers.get("origin") || "http://localhost:3000";
        return NextResponse.redirect(`${origin}/?error=stripe_error`, 303);
    }
}