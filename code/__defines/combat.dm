/*ALL DEFINES RELATED TO COMBAT GO HERE*/

//Damage and status effect defines

//Damage defines //TODO: merge these down to reduce on defines
/// Physical fracturing and warping of the material.
#define BRUTE "brute"
/// Scorching and charring of the material.
#define BURN "burn"
/// Poisoning. Mostly caused by reagents.
#define TOX "toxin"
/// Suffocation.
#define OXY "oxygen"

//bitflag damage defines used for suicide_act
#define BRUTELOSS (1<<0)
#define FIRELOSS (1<<1)
#define TOXLOSS (1<<2)
#define OXYLOSS (1<<3)
//Bitflags defining which status effects could be or are inflicted on a mob
/// If set, this mob can be stunned.
#define CANWEAKEN (1<<0)
#define CANSTUN (1<<1)
/// If set, this mob can be knocked unconscious via status effect.
/// NOTE, does not mean immune to sleep. Unconscious and sleep are two different things.
/// NOTE, does not relate to the unconscious stat either. Only the status effect.
#define CANUNCONSCIOUS (1<<2)
/// If set, this mob can be grabbed or pushed when bumped into
#define CANPUSH (1<<3)
/// Mob godmode. Prevents most statuses and damage from being taken, but is more often than not a crapshoot. Use with caution.
#define GODMODE (1<<4)

#define EFFECT_WEAKEN "weakened"
#define EFFECT_STUN "stun"
#define EFFECT_KNOCKDOWN "knockdown"
#define EFFECT_UNCONSCIOUS "unconscious"
#define EFFECT_PARALYZE "paralyze"
#define EFFECT_IMMOBILIZE "immobilize"

#define BODY_ZONE_HEAD "head"
#define BODY_ZONE_CHEST "chest"
#define BODY_ZONE_L_ARM "l_arm"
#define BODY_ZONE_R_ARM "r_arm"
#define BODY_ZONE_L_LEG "l_leg"
#define BODY_ZONE_R_LEG "r_leg"

GLOBAL_LIST_INIT(all_body_zones, list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))
GLOBAL_LIST_INIT(limb_zones, list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))
GLOBAL_LIST_INIT(arm_zones, list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
GLOBAL_LIST_INIT(leg_zones, list(BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))

#define BODY_ZONE_PRECISE_EYES "eyes"
#define BODY_ZONE_PRECISE_MOUTH "mouth"
#define BODY_ZONE_PRECISE_GROIN "groin"
#define BODY_ZONE_PRECISE_L_HAND "l_hand"
#define BODY_ZONE_PRECISE_R_HAND "r_hand"
#define BODY_ZONE_PRECISE_L_FOOT "l_foot"
#define BODY_ZONE_PRECISE_R_FOOT "r_foot"
