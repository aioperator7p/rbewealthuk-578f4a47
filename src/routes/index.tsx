import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Sparkles } from "lucide-react";

const facts = [
  "Honey never spoils. Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old and still edible.",
  "Octopuses have three hearts, nine brains, and blue blood.",
  "A day on Venus is longer than a year on Venus.",
  "Bananas are berries, but strawberries are not.",
  "The Eiffel Tower can grow more than 6 inches taller during the summer due to thermal expansion.",
  "Sharks existed before trees. Sharks have been around for about 400 million years, while trees appeared about 350 million years ago.",
  "There are more possible iterations of a game of chess than there are atoms in the observable universe.",
  "A group of flamingos is called a 'flamboyance'.",
  "Wombat poop is cube-shaped.",
  "The shortest war in history lasted only 38 to 45 minutes between Britain and Zanzibar in 1896.",
  "Your stomach gets a new lining every 3 to 4 days to prevent it from digesting itself.",
  "Cows have best friends and get stressed when separated from them.",
  "The Great Wall of China is not visible from space with the naked eye, contrary to popular belief.",
  "Sea otters hold hands while sleeping so they don't drift apart.",
  "A bolt of lightning is five times hotter than the surface of the sun.",
];

export const Route = createFileRoute("/")({
  component: Index,
  head: () => ({
    meta: [
      { title: "Random Facts Generator" },
      {
        name: "description",
        content: "Discover surprising and fun random facts with a single click.",
      },
    ],
  }),
});

function Index() {
  const [fact, setFact] = useState(facts[0]);
  const [isAnimating, setIsAnimating] = useState(false);

  const generateFact = () => {
    setIsAnimating(true);
    setTimeout(() => {
      let newFact = facts[Math.floor(Math.random() * facts.length)];
      while (newFact === fact && facts.length > 1) {
        newFact = facts[Math.floor(Math.random() * facts.length)];
      }
      setFact(newFact);
      setIsAnimating(false);
    }, 150);
  };

  return (
    <main className="flex min-h-screen items-center justify-center bg-background px-4 py-12">
      <div className="w-full max-w-2xl">
        <header className="mb-8 text-center">
          <div className="mb-4 inline-flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
            <Sparkles className="h-6 w-6 text-primary" />
          </div>
          <h1 className="text-4xl font-bold tracking-tight text-foreground sm:text-5xl">
            Random Facts
          </h1>
          <p className="mt-3 text-muted-foreground">
            Click the button to discover something new.
          </p>
        </header>

        <Card className="p-8 sm:p-10">
          <p
            className={`min-h-[6rem] text-lg leading-relaxed text-foreground transition-opacity duration-150 sm:text-xl ${
              isAnimating ? "opacity-0" : "opacity-100"
            }`}
          >
            {fact}
          </p>
        </Card>

        <div className="mt-6 flex justify-center">
          <Button size="lg" onClick={generateFact} className="gap-2">
            <Sparkles className="h-4 w-4" />
            Generate New Fact
          </Button>
        </div>
      </div>
    </main>
  );
}
