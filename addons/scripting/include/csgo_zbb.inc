#if defined _csgo_zbb_included_
  #endinput
#endif
#define _csgo_zbb_included_

#define TEAM_ZOMBIES			2
#define TEAM_BUILDERS			3
 
/**
 * Sets player's Credit.
 *
 * @param id    An integer.
 * @param value    An integer.
 * @return        None.
 */
native set_p_credit( id, value );


/**
 * Gets player's Credit.
 *
 * @param id    An integer.
 * @return        Returns player's carrying Credit.
 */
native get_p_credit( id );
