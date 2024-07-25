#define SOULCATCHER_ALLOW_CAPTURE 			0x1
#define SOULCATCHER_ALLOW_TRANSFER 			0x2
#define SOULCATCHER_ALLOW_DELETION 			0x4
#define SOULCATCHER_ALLOW_DELETION_INSTANT 	0x8

#define OXYLOSS_PASSOUT_THRESHOLD 50

// Flags for fully_heal().

/// Special flag that means this heal is an admin heal and goes above and beyond
/// Note, this includes things like removing suicide status and handcuffs / legcuffs, use with slight caution.
#define HEAL_ADMIN (1<<0)
/// Heals all brute damage.
#define HEAL_BRUTE (1<<1)
/// Heals all burn damage.
#define HEAL_BURN (1<<2)
/// Heals all toxin damage, slime people included.
#define HEAL_TOX (1<<3)
/// Heals all oxyloss.
#define HEAL_OXY (1<<4)
/// Heals all stamina damage.
#define HEAL_STAM (1<<5)
/// Restore all limbs to their initial state.
#define HEAL_LIMBS (1<<6)
/// Heals all organs from failing.
#define HEAL_ORGANS (1<<7)
/// A "super" heal organs, this refreshes all organs entirely, deleting old and replacing them with new.
#define HEAL_REFRESH_ORGANS (1<<8)
/// Removes all wounds.
#define HEAL_WOUNDS (1<<9)
/// Removes all brain traumas, not including permanent ones.
#define HEAL_TRAUMAS (1<<10)
/// Removes all reagents present.
#define HEAL_ALL_REAGENTS (1<<11)
/// Removes all non-positive diseases.
#define HEAL_NEGATIVE_DISEASES (1<<12)
/// Restores body temperature back to nominal.
#define HEAL_TEMP (1<<13)
/// Restores blood levels to normal.
#define HEAL_BLOOD (1<<14)
/// Removes all non-positive mutations (neutral included).
#define HEAL_NEGATIVE_MUTATIONS (1<<15)
/// Removes status effects with this flag set that also have remove_on_fullheal = TRUE.
#define HEAL_STATUS (1<<16)
/// Same as above, removes all CC related status effects with this flag set that also have remove_on_fullheal = TRUE.
#define HEAL_CC_STATUS (1<<17)
/// Deletes any restraints on the mob (handcuffs / legcuffs)
#define HEAL_RESTRAINTS (1<<18)

/// Combination flag to only heal the main damage types.
#define HEAL_DAMAGE (HEAL_BRUTE|HEAL_BURN|HEAL_TOX|HEAL_OXY|HEAL_STAM)
/// Combination flag to only heal things messed up things about the mob's body itself.
#define HEAL_BODY (HEAL_LIMBS|HEAL_ORGANS|HEAL_REFRESH_ORGANS|HEAL_WOUNDS|HEAL_TRAUMAS|HEAL_BLOOD|HEAL_TEMP)
/// Combination flag to heal negative things affecting the mob.
#define HEAL_AFFLICTIONS (HEAL_NEGATIVE_DISEASES|HEAL_NEGATIVE_MUTATIONS|HEAL_ALL_REAGENTS|HEAL_STATUS|HEAL_CC_STATUS)

/// Full heal that isn't admin forced
#define HEAL_ALL ~(HEAL_ADMIN|HEAL_RESTRAINTS)
/// Heals everything and is as strong as / is an admin heal
#define ADMIN_HEAL_ALL ALL
