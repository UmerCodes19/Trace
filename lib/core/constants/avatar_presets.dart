// lib/core/constants/avatar_presets.dart
// Curated Starter Identities & Palette Engine for the Trace Avatar System

/// Named color palettes — curated, intentional, never random
class AvatarPalette {
  final String name;
  final List<String> bg;
  final List<String> skin;
  final List<String> hair;
  final List<String> outfit;

  const AvatarPalette({
    required this.name,
    required this.bg,
    required this.skin,
    required this.hair,
    required this.outfit,
  });
}

const List<AvatarPalette> kCuratedPalettes = [
  AvatarPalette(
    name: 'Naturals',
    bg: ['#4ECDC4', '#1A535C', '#2D6A4F', '#588157', '#A7C957'],
    skin: ['#FFDBB5', '#E0A96D', '#8D5524', '#F9C9B1', '#C68642', '#3C2F2F', '#FFF0E0', '#5C3826'],
    hair: ['#2D3748', '#1A202C', '#5C3826', '#8D5524', '#3C2F2F', '#E2E8F0'],
    outfit: ['#4A5568', '#2D3748', '#718096', '#A0AEC0', '#1A202C'],
  ),
  AvatarPalette(
    name: 'Pastels',
    bg: ['#FFB5E8', '#B5DEFF', '#E7FFAC', '#DCD3FF', '#FFC9DE', '#AFF8DB'],
    skin: ['#FFDBB5', '#F9C9B1', '#FFF0E0', '#E0A96D', '#C68642'],
    hair: ['#DCD3FF', '#FFB5E8', '#B5DEFF', '#2D3748', '#5C3826'],
    outfit: ['#DCD3FF', '#B5DEFF', '#FFB5E8', '#AFF8DB', '#FFC9DE'],
  ),
  AvatarPalette(
    name: 'Vivid',
    bg: ['#FF6B6B', '#4ECDC4', '#FFE66D', '#FF758C', '#A18CD1', '#4FACFE'],
    skin: ['#FFDBB5', '#E0A96D', '#8D5524', '#F9C9B1', '#C68642', '#3C2F2F'],
    hair: ['#E53E3E', '#3182CE', '#38A169', '#9F7AEA', '#ED64A6', '#D69E2E'],
    outfit: ['#E53E3E', '#3182CE', '#805AD5', '#38A169', '#D69E2E'],
  ),
  AvatarPalette(
    name: 'Dark Academia',
    bg: ['#3E2723', '#4E342E', '#5D4037', '#1B1B2F', '#2C2C3A'],
    skin: ['#FFDBB5', '#E0A96D', '#F9C9B1', '#C68642', '#8D5524'],
    hair: ['#1A202C', '#2D3748', '#5C3826', '#3C2F2F'],
    outfit: ['#3E2723', '#4E342E', '#5D4037', '#795548', '#6D4C41'],
  ),
  AvatarPalette(
    name: 'Cyber Jade',
    bg: ['#004D40', '#00796B', '#00BFA5', '#1DE9B6', '#0D1615'],
    skin: ['#FFDBB5', '#E0A96D', '#8D5524', '#F9C9B1', '#C68642', '#3C2F2F'],
    hair: ['#00BFA5', '#1DE9B6', '#004D40', '#1A202C', '#E2E8F0'],
    outfit: ['#004D40', '#00796B', '#0D1615', '#1B2B28', '#00BFA5'],
  ),
  AvatarPalette(
    name: 'Earth Tones',
    bg: ['#A67C52', '#8B6F47', '#6B4226', '#D4A76A', '#C4956A'],
    skin: ['#FFDBB5', '#E0A96D', '#8D5524', '#C68642', '#5C3826', '#3C2F2F'],
    hair: ['#3C2F2F', '#5C3826', '#8D5524', '#1A202C'],
    outfit: ['#6B4226', '#8B6F47', '#A67C52', '#4A3728', '#5D4037'],
  ),
  AvatarPalette(
    name: 'Vaporwave',
    bg: ['#FF71CE', '#01CDFE', '#05FFA1', '#B967FF', '#FFFB96'],
    skin: ['#FFDBB5', '#F9C9B1', '#FFF0E0', '#E0A96D'],
    hair: ['#FF71CE', '#B967FF', '#01CDFE', '#05FFA1', '#E2E8F0'],
    outfit: ['#B967FF', '#FF71CE', '#01CDFE', '#1A202C'],
  ),
  AvatarPalette(
    name: 'Monochrome',
    bg: ['#2E2E2E', '#4A4A4A', '#1A1A1A', '#666666', '#333333'],
    skin: ['#FFDBB5', '#E0A96D', '#8D5524', '#F9C9B1', '#C68642', '#3C2F2F'],
    hair: ['#1A202C', '#2D3748', '#E2E8F0', '#718096'],
    outfit: ['#1A1A1A', '#2E2E2E', '#4A4A4A', '#666666', '#E2E8F0'],
  ),
];

/// Starter Identity — a complete curated avatar archetype
class StarterIdentity {
  final String name;
  final String emoji;
  final String tagline;
  final Map<String, dynamic> config;

  const StarterIdentity({
    required this.name,
    required this.emoji,
    required this.tagline,
    required this.config,
  });
}

final List<StarterIdentity> kStarterIdentities = [
  StarterIdentity(
    name: 'The Scholar',
    emoji: '📚',
    tagline: 'Knowledge is power',
    config: {
      'hair': 1, 'eyes': 0, 'mouth': 2, 'acc': 1, 'facialHair': 0,
      'details': 0, 'eyebrows': 2, 'noseStyle': 0, 'outfit': 5,
      'bgColor': '#1B1B2F', 'skinColor': '#FFDBB5', 'hairColor': '#2D3748',
      'outfitColor': '#4E342E', 'bgStyle': 1,
    },
  ),
  StarterIdentity(
    name: 'The Explorer',
    emoji: '🧭',
    tagline: 'Never stop wandering',
    config: {
      'hair': 8, 'eyes': 0, 'mouth': 0, 'acc': 0, 'facialHair': 3,
      'details': 0, 'eyebrows': 1, 'noseStyle': 0, 'outfit': 2,
      'bgColor': '#2D6A4F', 'skinColor': '#E0A96D', 'hairColor': '#5C3826',
      'outfitColor': '#6B4226', 'bgStyle': 0,
    },
  ),
  StarterIdentity(
    name: 'The Dreamer',
    emoji: '🌙',
    tagline: 'Head in the clouds',
    config: {
      'hair': 7, 'eyes': 10, 'mouth': 0, 'acc': 0, 'facialHair': 0,
      'details': 1, 'eyebrows': 0, 'noseStyle': 1, 'outfit': 6,
      'bgColor': '#DCD3FF', 'skinColor': '#F9C9B1', 'hairColor': '#9F7AEA',
      'outfitColor': '#B5DEFF', 'bgStyle': 1,
    },
  ),
  StarterIdentity(
    name: 'The Rebel',
    emoji: '🔥',
    tagline: 'Break the rules',
    config: {
      'hair': 19, 'eyes': 5, 'mouth': 3, 'acc': 2, 'facialHair': 0,
      'details': 0, 'eyebrows': 5, 'noseStyle': 2, 'outfit': 2,
      'bgColor': '#E53E3E', 'skinColor': '#C68642', 'hairColor': '#E53E3E',
      'outfitColor': '#1A202C', 'bgStyle': 0,
    },
  ),
  StarterIdentity(
    name: 'The Creator',
    emoji: '🎨',
    tagline: 'Art is everything',
    config: {
      'hair': 3, 'eyes': 3, 'mouth': 0, 'acc': 0, 'facialHair': 0,
      'details': 2, 'eyebrows': 1, 'noseStyle': 0, 'outfit': 0,
      'bgColor': '#FFE66D', 'skinColor': '#8D5524', 'hairColor': '#ED64A6',
      'outfitColor': '#805AD5', 'bgStyle': 2,
    },
  ),
  StarterIdentity(
    name: 'Night Owl',
    emoji: '🦉',
    tagline: 'Alive after midnight',
    config: {
      'hair': 14, 'eyes': 6, 'mouth': 2, 'acc': 4, 'facialHair': 0,
      'details': 0, 'eyebrows': 0, 'noseStyle': 0, 'outfit': 1,
      'bgColor': '#0D1615', 'skinColor': '#FFDBB5', 'hairColor': '#1A202C',
      'outfitColor': '#2D3748', 'bgStyle': 3,
    },
  ),
  StarterIdentity(
    name: 'Sunshine',
    emoji: '☀️',
    tagline: 'Radiate warmth',
    config: {
      'hair': 5, 'eyes': 2, 'mouth': 4, 'acc': 0, 'facialHair': 0,
      'details': 1, 'eyebrows': 1, 'noseStyle': 1, 'outfit': 0,
      'bgColor': '#FFE66D', 'skinColor': '#8D5524', 'hairColor': '#1A202C',
      'outfitColor': '#FF758C', 'bgStyle': 1,
    },
  ),
  StarterIdentity(
    name: 'The Architect',
    emoji: '📐',
    tagline: 'Design with intent',
    config: {
      'hair': 18, 'eyes': 7, 'mouth': 2, 'acc': 1, 'facialHair': 0,
      'details': 0, 'eyebrows': 2, 'noseStyle': 2, 'outfit': 3,
      'bgColor': '#1A535C', 'skinColor': '#E0A96D', 'hairColor': '#2D3748',
      'outfitColor': '#1A535C', 'bgStyle': 0,
    },
  ),
  StarterIdentity(
    name: 'The Minimalist',
    emoji: '◻️',
    tagline: 'Less is more',
    config: {
      'hair': 0, 'eyes': 0, 'mouth': 2, 'acc': 0, 'facialHair': 0,
      'details': 0, 'eyebrows': 4, 'noseStyle': 0, 'outfit': 3,
      'bgColor': '#E2E8F0', 'skinColor': '#FFDBB5', 'hairColor': '#2D3748',
      'outfitColor': '#E2E8F0', 'bgStyle': 0,
    },
  ),
  StarterIdentity(
    name: 'The Wanderer',
    emoji: '🌿',
    tagline: 'Find your path',
    config: {
      'hair': 12, 'eyes': 0, 'mouth': 0, 'acc': 0, 'facialHair': 1,
      'details': 2, 'eyebrows': 0, 'noseStyle': 0, 'outfit': 1,
      'bgColor': '#588157', 'skinColor': '#C68642', 'hairColor': '#3C2F2F',
      'outfitColor': '#A67C52', 'bgStyle': 1,
    },
  ),
  StarterIdentity(
    name: 'Tech Phantom',
    emoji: '👾',
    tagline: 'Ghost in the machine',
    config: {
      'hair': 23, 'eyes': 9, 'mouth': 2, 'acc': 2, 'facialHair': 0,
      'details': 0, 'eyebrows': 5, 'noseStyle': 2, 'outfit': 2,
      'bgColor': '#0D1615', 'skinColor': '#3C2F2F', 'hairColor': '#00BFA5',
      'outfitColor': '#004D40', 'bgStyle': 3,
    },
  ),
  StarterIdentity(
    name: 'Velvet Static',
    emoji: '🎵',
    tagline: 'Feel the frequency',
    config: {
      'hair': 22, 'eyes': 4, 'mouth': 3, 'acc': 4, 'facialHair': 0,
      'details': 0, 'eyebrows': 1, 'noseStyle': 0, 'outfit': 1,
      'bgColor': '#B967FF', 'skinColor': '#8D5524', 'hairColor': '#1A202C',
      'outfitColor': '#FF71CE', 'bgStyle': 2,
    },
  ),
  StarterIdentity(
    name: 'Lunar Kid',
    emoji: '🌕',
    tagline: 'Quiet brilliance',
    config: {
      'hair': 21, 'eyes': 8, 'mouth': 0, 'acc': 0, 'facialHair': 0,
      'details': 1, 'eyebrows': 0, 'noseStyle': 1, 'outfit': 6,
      'bgColor': '#1B1B2F', 'skinColor': '#F9C9B1', 'hairColor': '#E2E8F0',
      'outfitColor': '#DCD3FF', 'bgStyle': 3,
    },
  ),
  StarterIdentity(
    name: 'The Archivist',
    emoji: '🗂️',
    tagline: 'Every detail matters',
    config: {
      'hair': 6, 'eyes': 0, 'mouth': 0, 'acc': 1, 'facialHair': 0,
      'details': 0, 'eyebrows': 2, 'noseStyle': 0, 'outfit': 5,
      'bgColor': '#5D4037', 'skinColor': '#FFDBB5', 'hairColor': '#5C3826',
      'outfitColor': '#3E2723', 'bgStyle': 0,
    },
  ),
  StarterIdentity(
    name: 'Echo',
    emoji: '🔮',
    tagline: 'Between worlds',
    config: {
      'hair': 15, 'eyes': 9, 'mouth': 3, 'acc': 0, 'facialHair': 0,
      'details': 0, 'eyebrows': 1, 'noseStyle': 0, 'outfit': 0,
      'bgColor': '#01CDFE', 'skinColor': '#E0A96D', 'hairColor': '#B967FF',
      'outfitColor': '#05FFA1', 'bgStyle': 2,
    },
  ),
  StarterIdentity(
    name: 'Neon Poet',
    emoji: '✨',
    tagline: 'Words that glow',
    config: {
      'hair': 16, 'eyes': 10, 'mouth': 0, 'acc': 0, 'facialHair': 0,
      'details': 1, 'eyebrows': 1, 'noseStyle': 1, 'outfit': 4,
      'bgColor': '#FF71CE', 'skinColor': '#FFF0E0', 'hairColor': '#FF71CE',
      'outfitColor': '#B967FF', 'bgStyle': 1,
    },
  ),
];
