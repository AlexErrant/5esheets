import { onCleanup } from "solid-js";
import { createStore, reconcile } from "solid-js/store";
import { CharacterSchema } from '~/5esheets-client';

export const proficiencies = ["none", "master", "expert"] as const;
export type Proficiency = (typeof proficiencies)[number];

const proficiencyMultiplier: Record<Proficiency, 0 | 1 | 2> = {
  none: 0,
  master: 1,
  expert: 2,
}

const douglas: CharacterSchema = {
  id: 1,
  player_id: 1,
  party_id: 1,
  name: "Douglas McTrickfoot",
  slug: "douglas-mctrickfoot",
  class_: "Artilleur",
  level: 4,
  data: {
    experiencepoints: 0,
    background: "Artistan",
    playername: "Balthazar",
    race: "Gnome",
    alignment: "Chaotique Bon",
    Strengthscore: "8",
    Strengthmod: "-1",
    Dexterityscore: "14",
    Dexteritymod: "+2",
    Constitutionscore: "12",
    Constitutionmod: "+1",
    Intelligencescore: "18",
    Intelligencemod: "+4",
    Wisdomscore: "12",
    Wisdommod: "+1",
    Charismascore: "14",
    Charismamod: "+2",
    darkvision: true,
    proficiencybonus: "+2",
    "Strength-save": "-1",
    "Dexterity-save": "+2",
    "Constitution-save-prof": true,
    "Constitution-save": "+3",
    "Wisdom-save": "+1",
    "Intelligence-save-prof": true,
    "Intelligence-save": "+6",
    "Charisma-save": "+2",
    Acrobatics: "+2",
    Arcana: "+4",
    Athletics: "-1",
    Stealth: "+2",
    "Animal Handling": "+1",
    "Sleight of Hand": "+2",
    "History-prof": true,
    History: "+6",
    Intimidation: "+2",
    Investigation: "+4",
    Medicine: "+1",
    Nature: "+4",
    "Perception-prof": true,
    Perception: "+3",
    "Insight-prof": true,
    Insight: "+3",
    "Persuasion-prof": true,
    Persuasion: "+4",
    Religion: "+4",
    Performance: "+2",
    Survival: "+1",
    Deception: "+2",
    passiveperception: "13",
    otherprofs:
      "**Outils**\r\n- menuisier\r\n- souffleur de verre\r\n- bricolage\r\n- voleur\r\n- forgeron\r\n\r\n**Langues**\r\n- Nain\r\n- Gnome\r\n- Commun\r\n\r\n**Armes**\r\n- légères",
    ac: "14",
    initiative: "+2",
    speed: "25",
    maxhp: "33",
    temphp: "0",
    currenthp: "33",
    totalhd: "1d8",
    remaininghd: "4",
    "custom-1-header": "Infusions",
    "custom-1-remaining": "3",
    "custom-1-available": "3",
    "custom-2-header": "Canon",
    "custom-2-remaining": "1",
    "custom-2-available": "1",
    "custom-3-header": "Bag. secrets",
    "custom-3-remaining": "3",
    "custom-3-available": "3",
    atkname1: "Arbalète légère",
    atkbonus1: "+4",
    atkdamage1: "1d8+2 perçants",
    atkname2: "Marteau léger",
    atkbonus2: "+4",
    atkdamage2: "1d4+2 contondants",
    atkname3: "Hache à une main",
    atkbonus3: "+4",
    atkdamage3: "1d6+2 tranchants",
    equipment:
      "- Armure de cuir clouté\r\n- [Baguette des secrets](https://roll20.net/compendium/dnd5e/Wand%20of%20Secrets#content) \r\n- Focalisateur arcanique\r\n- Livre traitant de la fabrication d'homoncules en bois\r\n- Carnets de notes de Siméon\r\n",
    gp: "1",
    personality:
      "Douglas est astucieux et fait preuve d'une répartie rapide. Il est fidèle envers ses amis et curieux d'apprendre des nouveaux sujets.",
    ideals:
      "Douglas rêve de maîtriser la magie à la seule force de son intellect.",
    bonds:
      "Douglas est particulièrement fidèle envers les membres de sa famille, et se sent responsable de Crounch.",
    flaws:
      "Douglas est impulsif. Son besoin de paraître intelligent cache un manque de confiance en soi. ",
    features:
      "**Bricolage**\r\n- 1h pour bricoler 1 objet\r\n- jusqu'à 3 objets \r\n  * boîte à musique\r\n  * jouet mécanique en bois\r\n  * allume feu\r\n\r\n**Bricolage magique**\r\n- sur objet minuscule\r\n- jusqu'à 3\r\n  * peut jouer un message enregistré\r\n  * peut jouer un son continu\r\n\r\n**Infusions**\r\n- 4 connues\r\n- jusqu'à 3 objets en même temps\r\n- dure 3 jours\r\n\r\n**Right tool**\r\n1h pour crafter des objets d'artisan\r\n\r\n**Canon occulte**\r\n- 1 action pour invoquer/faire disparaître\r\n- 1 action bonus pour utiliser\r\n * lance-flamme: 🔺 DEX save ? 2d8 🔥 : 1/2\r\n * baliste: 🏹 40m. 2d8 💪 + 1.5m recul\r\n * protecteur: 3m ⭕, 1d8@int_mod temp HP",
    remainingdailyspells: "0",
    dailypreparedspells: "6",
    spelldc: "14",
    totalspellattackbonus: "+6",
    "spells-lvl0-1":
      "🗣️ 👋 💎 [Mending](https://5e.tools/spells.html#mending_phb)",
    "spells-lvl0-2":
      "🅰️ 🗣️ 👋 [Fire Bolt](https://5e.tools/spells.html#fire%20bolt_phb)  (@cantrip_die@d10 🔥)",
    "spells-slots-available-lvl1": "3",
    "spells-slots-total-lvl1": "3",
    "spells-lvl1-1":
      "🅰️ 🗣️ 👋 🧙 [Thunderwave](https://5e.tools/spells.html#thunderwave_phb): CON 💾 | 2d8 ⛈️",
    "spells-lvl1-2":
      "➰ 🗣️ 👋 🧙 [Shield](https://5e.tools/spells.html#shield_phb) + 5AC",
    "spells-lvl1-3-prepped": true,
    "spells-lvl1-3":
      "🅰️ 🗣️ 👋 💎 ©️ [Caustic Brew](https://5e.tools/spells.html#tasha's%20caustic%20brew_tce) DEX 💾 |2d4🧪",
    "spells-lvl1-4-prepped": true,
    "spells-lvl1-4":
      "🅰️ 👋 [Catapult](https://5e.tools/spells.html#catapult_xge) DEX 💾 | 3d8 🔨",
    "spells-lvl1-5-prepped": true,
    "spells-lvl1-5":
      "®️ 🗣️ 👋 [Detect Magic](https://5e.tools/spells.html#detect%20magic_phb)",
    "spells-lvl1-6-prepped": true,
    "spells-lvl1-6":
      "➰ 👋 [Absorb Elements](https://5e.tools/spells.html#absorb%20elements_xge)",
    "spells-lvl1-7-prepped": true,
    "spells-lvl1-7":
      "🅰️ 🗣️ 👋 💎 [False Life](https://5e.tools/spells.html#false%20life_phb) 1d4+4 + 5*spell_lvl ❣️",
    "spells-lvl1-8-prepped": true,
    "spells-lvl1-8":
      "🆎 🗣️ 👋 💎 [Sanctuary](https://5e.tools/spells.html#sanctuary_phb)",
  },
};
const store = {[douglas.slug]: douglas}

const [characters, setCharacters] = createStore(store);

export default function useStore() {
  return [
    characters,
    {
      update: (characterSlug: string, update: Partial<CharacterSchema>) => {
        const proficiencyBonus = parseInt(update.data?.proficiencyBonus|| characters[characterSlug].data.proficiencyBonus || 0)

        const computedData = {
          ...('Charismascore' in update.data! ? {
            Charismamod: scoreToSkillModifier(update.data.Charismascore),
            "Charisma-save": scoreToProficiencyModifier(update.data.Charismascore, update.data["Charisma-prof"] ? 'master' : 'none', proficiencyBonus),
            "Intimidation": scoreToProficiencyModifier(update.data.Charismascore, update.data["Intimidation-prof"] ? 'master' : 'none', proficiencyBonus),
            "Persuasion": scoreToProficiencyModifier(update.data.Charismascore, update.data["Persuasion-prof"] ? 'master' : 'none', proficiencyBonus)
          } : {}),
        }

        setCharacters(characterSlug, {...characters[characterSlug], ...update, data: {...characters[characterSlug].data, ...update.data, ...computedData}})
      }
    }
  ] as const
}

const scoreToSkillModifier = (score: number): string =>
  formatModifier(Math.floor((score - 10) / 2))

const scoreToProficiencyModifier = (score: number, proficiency: Proficiency, proficiencyBonus: number): string =>
  formatModifier(Math.floor((score - 10) / 2) + proficiencyMultiplier[proficiency] * proficiencyBonus)

const formatModifier = (mod: number): string => mod > 0 ? `+${mod}` : `${mod}`