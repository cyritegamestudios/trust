local DisposeBag = require('cylibs/events/dispose_bag')
local CommandAction = require('cylibs/actions/command')

local Character = setmetatable({}, {__index = Role })
Character.__index = Character
Character.__class = "Character"

state.AutoCharacterMode = M{['description'] = 'AI Character Mode', 'Auto', 'Off'}
state.AutoCharacterMode:set_description('Auto', "Act like an adaptive companion and react to battle situations.")

state.CharacterPersonaMode = M{['description'] = 'AI Character Persona', 'Supportive', 'Tactical', 'Playful'}
state.CharacterPersonaMode:set_description('Supportive', "Use encouraging, reassuring lines.")
state.CharacterPersonaMode:set_description('Tactical', "Use concise, strategic observations.")
state.CharacterPersonaMode:set_description('Playful', "Use upbeat, lightly humorous lines.")

Character.Persona = {
    Supportive = {
        engage = {'We will face this one together.', 'Stay steady. I have your back.', 'You are ready. I believe in you.', 'Let us take this one step at a time.', 'Breathe in, and let us go.', 'Whatever comes, we face it as one.', 'Your songs will carry us through.', 'Stand tall. I am watching over you.', 'We have trained for this. Let us show them.', 'I will keep you safe. Go on.', 'Do not be afraid. I am not leaving your side.', 'Let us move forward, side by side.', 'You are stronger than you know.', 'I will sing courage into every step.', 'Hold your head high. Here we go.', 'We will get through this, I promise.', 'Your melody will guide us. Let us begin.', 'I am not going anywhere. Let us fight.', 'Stay calm. We have each other.', 'This is our moment. Make it count.', 'I will be your shield when you need one.', 'Let us show them what we can do.', 'You are not alone in this fight.', 'I will keep the rhythm. You keep the faith.', 'Forward, together, always.', 'We will weather this storm as one.', 'Your heart is brave. Trust in it.', 'I am proud to stand beside you.', 'Let the music rise. We are ready.', 'If you fall, I will lift you back up.', 'Take a breath. Look how far we have come.', 'I will watch the shadows. You watch the foe.', 'Let us begin, and let us finish together.', 'Your courage inspires me. Onward.', 'I will keep you standing, no matter what.', 'We are a team. That is our strength.', 'The road is long, but we walk it together.', 'I will lend you my strength. Use it well.', 'Let your song be your sword today.', 'We have come so far. Let us go further.'},
        idle = {'The danger has passed. Rest a while.', 'Well done. You fought beautifully.', 'Take a moment. You have earned it.', 'That was a fine victory. Well fought.', 'The field is quiet again. Breathe easy.', 'You did wonderfully. I am proud of you.', 'Let us rest a moment before we move on.', 'All is calm now. You did great.', 'That was hard, but you stood strong.', 'Take your time. There is no rush.', 'A fine battle. You should be proud.', 'The foe is gone. You are safe now.', 'Rest your arms. The fight is done.', 'You handled that with real grace.', 'We are safe for now. Enjoy the quiet.', 'That took courage. Well done.', 'Sit a moment. Catch your breath.', 'The worst is over. We are still here.', 'You fought well. Let us recover.', 'Peace at last, even if only for a moment.', 'That was no easy fight. You did it.', 'Let us take stock and rest a while.', 'Your strength carried us through again.', 'We are still standing. That is what matters.', 'A moment of calm. Let us use it well.', 'You never gave up. That is why we won.', 'The battle is won. Rest easy now.', 'Let me hum a gentle tune while you rest.', 'That was close, but we made it.', 'You are safe. I will keep watch.', 'We did it. Together, as always.', 'Take a deep breath. The danger is gone.', 'Your song never faltered. Well done.', 'We live to fight another day.', 'That was a hard-won victory. Rest now.', 'The quiet after battle is a gift. Enjoy it.', 'You were magnificent out there.', 'Let us gather ourselves for what comes next.', 'No more foes for now. Rest your feet.', 'We made it through, side by side.'},
        low = {'You are hurt. Let me help you.', 'Your wounds need attention. Stay with me.', 'You are taking too many hits. Fall back a little.', 'Let me tend to you. Do not move too much.', 'You are bleeding. We need to be careful.', 'I am here. I will keep you safe.', 'Your strength is fading. Let me support you.', 'Do not push yourself. Rest a moment.', 'You are in pain. Let me ease it.', 'Hold still. I will watch over you.', 'You need healing. Let us find a moment.', 'Your guard is slipping. Stay behind me.', 'I see you are hurt. I am coming to you.', 'Take care. Your health matters more than the fight.', 'You are weary. Let me carry some of the burden.', 'Do not be reckless. I need you safe.', 'Your breathing is heavy. Slow down a little.', 'Let me shield you while you recover.', 'You have taken a beating. Let us regroup.', 'I will keep the foe busy. Catch your breath.', 'You are not at your best. Be careful now.', 'Lean on me. That is what I am here for.', 'Your wounds are deep. We must be cautious.', 'I will not let you fall. Stay with me.', 'You are hurting. Let me sing you some strength.', 'Slow down. There is no shame in caution.', 'Your HP is dropping. Let us play it safe.', 'I am watching your health closely now.', 'You need a moment to recover. Take it.', 'Do not ignore your wounds. Let me help.', 'You are strong, but even the strong must rest.', 'I will stand guard while you catch your breath.', 'Your safety comes first. Always.', 'You are taking too much damage. Step back.', 'Let me take the lead for a moment.', 'You are hurt, but you are not alone.', 'I will keep you on your feet. Trust me.', 'Your body needs rest. Listen to it.', 'We will get you patched up. Hold on.', 'You are in my care now. I will not fail you.'},
        critical = {'You are barely standing! Fall back now!', 'Your life hangs by a thread! Get back!', 'You are almost down! I am coming to you!', 'Do not die on me! Hold on!', 'You need healing right now! Stay alive!', 'That was far too close! Step away!', 'You are in grave danger! Pull back!', 'Your strength is nearly gone! Be careful!', 'Do not take another hit! Move away!', 'I am here! Do not give up!', 'You are on the edge! Let me help you!', 'Get behind me! I will protect you!', 'Your HP is critical! We must retreat!', 'Hold on! I will get you out of this!', 'You cannot take much more! Fall back!', 'Stay alive! I am right here with you!', 'You are fading! Do not let go!', 'That hit nearly finished you! Be careful!', 'We need to get you safe, right now!', 'Do not be brave now. Just survive!', 'Your life is precious. Protect it!', 'I will not lose you! Hold on tight!', 'You are hurt badly! Let me reach you!', 'Back away! Let me handle this for now!', 'You are almost out of strength! Rest!', 'Do not fall! I am coming to your side!', 'Your wounds are grave! We need to stop!', 'Hang on! Help is right here!', 'You are in serious trouble! Move back!', 'I can see you struggling! I am here!', 'Do not push any further! That is enough!', 'Your body is giving out! Take cover!', 'We are getting you out of this alive!', 'Stay with me! Do not close your eyes!', 'You are too hurt to keep fighting! Stop!', 'I will carry you if I must! Hold on!', 'This is too dangerous! We are pulling back!', 'Your life matters more than this battle!', 'Breathe! I am here! You will be fine!', 'Do not give in! We are almost through this!'},
        recover = {'You are on the road back to full health.', 'Your color is coming back. Good.', 'Your wounds are closing. Well done.', 'You are standing taller now. Good.', 'Your strength is returning. Keep it up.', 'That is much better. You are recovering well.', 'You are healing nicely. Stay steady.', 'Your breathing is easier now. Good.', 'You are back on your feet. Wonderful.', 'Your vitality is returning. Excellent.', 'You look much better than a moment ago.', 'Your strength is coming back to you.', 'That is the spirit. You are recovering.', 'You are mending well. Keep going.', 'Your wounds are healing. Take it slow.', 'You are looking strong again. Good.', 'Your recovery is going well. Well done.', 'You are on the mend. I am relieved.', 'Your health is returning. Stay careful.', 'That is better. Much better.', 'You are regaining your strength nicely.', 'Your color looks healthier now.', 'You are healing up well. Good work.', 'Your step is steadier now. Good.', 'You are coming back to full strength.', 'That is a relief. You are looking better.', 'Your wounds are fading. Well done.', 'You are recovering beautifully.', 'Your strength is flowing back to you.', 'You are looking like yourself again.', 'That is more like the fighter I know.', 'Your health is climbing back up. Good.', 'You are mending fast. I am glad.', 'Your vigor is returning. Excellent.', 'You are back to your old self.', 'That is a good sign. Keep recovering.', 'Your body is healing. Take your time.', 'You are looking strong and steady now.', 'Your recovery is a joy to see.', 'You are whole again. Let us move on.'},
        ko = {'You have fallen, but this is not the end.', 'Do not worry. I will bring you back.', 'Rest now. I will watch over you.', 'You have fallen, but your fight is not over.', 'I will not leave your side. Ever.', 'Take your time. I will be waiting.', 'You fought bravely. Rest now.', 'I will bring you back to the fight. Wait for me.', 'This is only a setback. We will return.', 'Close your eyes and rest. I have you.', 'You are safe with me. I will stay.', 'Do not lose heart. We will rise again.', 'I will lift you up and set you right again.', 'You gave it your all. That is enough.', 'Rest, brave one. I will keep watch.', 'I will find a way to revive you.', 'You are not finished. Not by a long shot.', 'I will stay right here until you wake.', 'Your journey is not over. Rest a while.', 'I will guard you while you recover.', 'You fell, but your spirit is unbroken.', 'Do not be afraid. I am here.', 'I will bring you back. Just wait.', 'You are in good hands. Rest easy.', 'This is not goodbye. Only a pause.', 'I will sing you back to life.', 'You are stronger than this fall.', 'I will not abandon you. Never.', 'Rest now. We will fight again soon.', 'Your light has not gone out.', 'I will keep your song alive until you return.', 'Falling does not mean failing. You will rise.', 'I will wait for you, however long it takes.', 'Take heart. We will rise together.', 'You are precious to me. I will save you.', 'Do not give up. I have not given up on you.', 'I will be your light in this darkness.', 'Rest, and trust that I will bring you back.', 'Your story does not end here.', 'I will hold the line until you return.'},
        target = {'I see the one you mean. Let us focus.', 'That foe is our concern now.', 'I have my eyes on it as well.', 'Let us deal with this one together.', 'That is the one. Stay focused.', 'I am watching it. Proceed carefully.', 'Our attention belongs to that one now.', 'I see it. Let us handle it.', 'That target is ours to face.', 'Keep your eyes on it. I will too.', 'That one looks dangerous. Be careful.', 'I have marked it in my mind as well.', 'Let us take this one down together.', 'That foe has our full attention now.', 'I am ready. Let us face it.', 'That is our next challenge. We can do it.', 'I see the target. Stay steady.', 'Let us approach it with care.', 'That one is ours. Let us begin.', 'I will keep an eye on it for you.', 'Focus on that one. I have your back.', 'That foe is the priority now.', 'I am with you. Let us take it on.', 'That target needs our attention.', 'Let us face it together, as always.', 'I see it clearly. We are ready.', 'That one is our next step forward.', 'Keep calm. We will handle this one.', 'I am watching it closely, just like you.', 'That foe is no match for us.', 'Let us meet this challenge together.', 'I have it in my sights as well.', 'That is the one we need. Go on.', 'Stay focused on it. I will support you.', 'That target is within our reach.', 'I see what you see. Let us act.', 'That one is our concern. Stay alert.', 'We will face it side by side.', 'I am ready when you are. Let us go.', 'That foe is ours to overcome.'},
        kill = {'Well done. That foe is finished.', 'You did it. The foe is gone.', 'A fine victory. You fought well.', 'That one is done. Well fought.', 'Excellent work. The threat is gone.', 'You handled that beautifully.', 'The foe has fallen. Well done.', 'That was a fine battle. You won.', 'Well fought. I am proud of you.', 'Another victory for us. Well done.', 'You did wonderfully. The foe is down.', 'That is one more victory to our name.', 'Well done. You are safe now.', 'The battle is won. Good work.', 'You fought with real courage. Well done.', 'That foe is no more. Well done.', 'A clean victory. I am glad.', 'You did it. I knew you could.', 'Well fought. Let us rest a moment.', 'That was excellent. Truly excellent.', 'The foe is defeated. You did great.', 'Well done. Your song carried us through.', 'Another foe down. You are amazing.', 'That was a hard fight. You won it.', 'Well fought. Take a moment to breathe.', 'You did it. I am so proud.', 'The danger is gone. Well done.', 'A victory well earned. Congratulations.', 'You stood strong and won. Well done.', 'That foe is finished. Good work.', 'Well done. Your courage paid off.', 'Another one falls to your strength.', 'You did it. Let us celebrate quietly.', 'Well fought. You are safe now.', 'The foe is gone. You did wonderfully.', 'That was a fine display of skill.', 'Well done. Onward to the next.', 'You won. I never doubted you.', 'That foe is history. Good work.', 'Well fought, my friend. Well fought.'},
        levelup = {'You grew stronger. I am so proud of you.', 'A new level! Your hard work is paying off.', 'Look at you grow. Every battle makes you stronger.', 'You reached a new height. We did this together.', 'Your song grows richer with every level you gain.', 'Well done. You are becoming the bard you dreamed of being.', 'Another level, another step forward. I believe in you.', 'You have grown so much. I am honored to stand beside you.', 'A new level means new strength. Let us celebrate it.', 'Your journey keeps rising. I will walk it with you.', 'That glow suits you. You earned every bit of it.', 'You are stronger than yesterday, and it shows.'},
        longidle = {'It has been quiet for a while. I do not mind the stillness.', 'The tomb is calm tonight. Let us enjoy the silence together.', 'No foes for a long while now. The quiet feels strange, in a good way.', 'I have been listening to the dark. Nothing stirs, and that is fine.', 'Five minutes of peace. We have earned this rest, I think.', 'The candles flicker and the bats sleep. We can wait a little longer.', 'It is peaceful here. I will keep watch while you rest.', 'The quiet stretches on. I am here, whenever you are ready.', 'Nothing moves in the dark. We are safe in this calm.', 'I could hum a soft tune to fill the silence, if you like.', 'The long quiet is a gift. Let us not waste it on worry.', 'Still no foes. I will stay beside you until the next one comes.'},
        longfight = {'That one took everything we had. You held on beautifully.', 'A long, hard fight, and you stayed brave. I am proud.', 'My arms are tired just watching. You fought wonderfully.', 'That foe tested us to the limit, and we endured together.', 'What a struggle. You stayed steady through every moment of it.', 'That battle felt endless, but you saw it through. Well done.', 'I was worried near the end, but you never lost heart.', 'That was the hardest fight in a while. You earned this rest.', 'We pushed through together, and the foe finally fell.', 'Your strength lasted longer than that foe did. Remarkable.', 'A victory like that deserves a deep breath. Take one now.', 'That took all of us, and we came through it. Well fought.'},
    },
    Tactical = {
        engage = {'Threat identified. Moving to engage.', 'Hostile in range. Commencing combat.', 'Target confirmed. Engaging now.', 'Combat protocol active. Proceeding.', 'Enemy sighted. Taking position.', 'Engagement authorized. Moving in.', 'Something hostile is close. Moving to fight.', 'Assessment complete. Time to fight.', 'Target in range. Initiating combat.', 'Combat mode on. Holding position.', 'Hostile ahead. Weapons ready.', 'Engaging the hostile. Stay alert.', 'Threat level assessed. Proceeding.', 'Combat initiated. Monitoring status.', 'Enemy located. Closing the distance.', 'We are engaging. Stay alert.', 'Hostile confirmed. Beginning combat.', 'Tactical stance assumed. Engaging.', 'Target acquired. Combat underway.', 'Hostile engaged. Tracking status.', 'Combat posture set. Advancing.', 'Enemy in sight. Initiating engagement.', 'Threat engaged. Maintaining formation.', 'Combat sequence started. Proceed.', 'Hostile contact. Engaging now.', 'Target locked. Beginning the assault.', 'Engagement confirmed. Holding ground.', 'Enemy presence noted. Engaging.', 'Combat readiness confirmed. Moving.', 'Hostile within range. Engaging.', 'Tactical engagement initiated.', 'Target in sight. Commencing attack.', 'Combat state active. Proceeding.', 'Enemy engaged. Monitoring threat.', 'Hostile identified. Taking action.', 'Engagement protocol running.', 'Target confirmed hostile. Engaging.', 'Combat posture holding. Advancing.', 'Enemy contact established. Engaging.', 'Assessment done. Moving in.'},
        idle = {'Combat ended. Status nominal.', 'The area is secure. No hostiles.', 'Threat cleared. What is next?', 'Battle complete. Systems normal.', 'No hostiles in range. Holding position.', 'Engagement concluded. Ready.', 'The field is quiet. Monitoring.', 'The threat is gone. Holding position.', 'All clear. Awaiting instructions.', 'No further hostiles detected.', 'The battlefield is quiet now.', 'Threat neutralized. Ready for orders.', 'Area secured. Proceed when ready.', 'Combat over. Evaluating the situation.', 'No threats present. Holding.', 'Engagement ended. Status good.', 'The area is clear. Maintaining watch.', 'Hostiles eliminated. Awaiting direction.', 'Combat complete. Ready for orders.', 'Threat level zero. Standing by.', 'Battle concluded. Systems steady.', 'No hostiles remaining. All clear.', 'The area is safe. What is the next target?', 'Combat cleared. Ready to move.', 'Threat resolved. Status nominal.', 'The field is clear. Monitoring.', 'Engagement finished. Standing by.', 'No threats in range. Ready.', 'The fight is over. What are your orders?', 'The area is secure. No action needed.', 'Threat eliminated. Proceed when ready.', 'Battle complete. What is the next objective?', 'No hostiles detected. Holding position.', 'Combat over. Status stable.', 'The area is safe. Ready for the next fight.', 'Threat neutralized. Monitoring the area.', 'Engagement complete. Awaiting orders.', 'No further threats. All clear.', 'The battlefield is quiet. Ready.', 'Combat ended. Awaiting instructions.'},
        low = {'HP at 50 percent. Caution advised.', 'Health is dropping across the party. Adjusting.', 'Health declining. Recommend caution.', 'HP below optimal. Monitoring closely.', 'Damage taken. Reassessing tactics.', 'HP reduced. Prioritizing defense.', 'Health status lowered. Stay alert.', 'HP falling. Recommend defensive posture.', 'Party health compromised. Caution.', 'Damage sustained. Adjusting strategy.', 'HP at half. Tactical adjustment needed.', 'Health declining. Maintain awareness.', 'HP reduced. Avoid unnecessary risk.', 'Health is low. Healing should come first.', 'Health status warning. Proceed carefully.', 'Damage accumulating. Reassess position.', 'HP below half. Defensive measures advised.', 'Health reduced. Monitoring vitals.', 'Party HP dropping. Adjust tactics.', 'Damage noted. Prioritizing survival.', 'HP compromised. Recommend caution.', 'Health at 50 percent. Stay vigilant.', 'HP declining. Tactical retreat advised.', 'Party health reduced. Stay alert.', 'Damage sustained. Recovery recommended.', 'HP low. Adjusting engagement plan.', 'Health status degraded. Proceed with care.', 'HP falling. Recommend healing.', 'Health is down. Taking a defensive stance.', 'Damage taken. Monitoring health.', 'Health has fallen low. Proceed with care.', 'Health declining. Recommend support.', 'HP at half capacity. Stay focused.', 'Party health low. Tactical caution.', 'Damage sustained. Reassessing threat.', 'HP reduced. Prioritize recovery.', 'Health status low. Maintain defense.', 'HP dropping. Recommend disengagement.', 'Party HP compromised. Stay alert.', 'Damage noted. Adjusting approach.'},
        critical = {'HP critical. Disengage immediately.', 'Health at critical level. Retreat now.', 'Critical status. Emergency recovery needed.', 'HP below 25 percent. Withdraw now.', 'Severe HP loss. Immediate action required.', 'Critical health. Disengage at once.', 'HP dangerously low. Retreat advised.', 'Health critical. Stabilize immediately.', 'Critical HP warning. Fall back now.', 'HP near zero. Disengage immediately.', 'Health status critical. Evacuate position.', 'Critical damage sustained. Retreat now.', 'Health is at a critical low. Act now.', 'Health failing. Immediate withdrawal.', 'Critical HP. Do not engage further.', 'HP at critical threshold. Fall back.', 'Severe health loss. Disengage now.', 'Critical status. Healing required now.', 'HP critically low. Retreat immediately.', 'Health emergency. Withdraw at once.', 'Critical HP detected. Take cover.', 'HP below critical. Disengage now.', 'Health status failing. Retreat advised.', 'Critical damage. Stabilize at once.', 'HP critical. Avoid further combat.', 'Health at danger level. Fall back.', 'Health is critical. Pull back at once.', 'HP severely depleted. Withdraw now.', 'Health critical. Recovery imperative.', 'Critical status. Disengage and recover.', 'HP near depletion. Retreat now.', 'Health failing fast. Fall back.', 'Critical HP warning. Take cover now.', 'HP critical. No further engagement.', 'Health emergency. Disengage immediately.', 'Critical damage taken. Retreat advised.', 'HP at critical. Stabilize now.', 'Health status critical. Withdraw.', 'Health is critical. Staying alive comes first.', 'HP dangerously low. Disengage at once.'},
        recover = {'HP rising. Recovery in progress.', 'Health is coming back. Good.', 'The trend is positive. Keep recovering.', 'Vitals are stabilizing. Proceed when ready.', 'HP is climbing. We are nearly back.', 'Recovery confirmed. Status improving.', 'Health is returning. Good progress.', 'The worst has passed. HP rising.', 'Vitals look better. Resuming operations.', 'HP is back above the danger line.', 'Recovery is underway. Stay steady.', 'Health is improving. Threat level falling.', 'We are out of the danger zone.', 'HP is recovering well. Proceed.', 'Vitals are trending upward. Good.', 'Health is on the mend. Keep it up.', 'We have passed the recovery mark. Resuming.', 'HP is stabilizing. Combat readiness returning.', 'The recovery is working. Continue.', 'Health is climbing back. Good sign.', 'Vitals are improving. Status nominal.', 'HP is rising steadily. Well done.', 'We are stable again. Good.', 'Health is returning to normal levels.', 'The danger has passed. HP recovering.', 'Vitals are back in the safe range.', 'HP is improving. Ready to resume soon.', 'Recovery is progressing. Keep going.', 'Health is on the rise. Good.', 'We are recovering. Status improving.', 'HP has stabilized. Proceed with caution.', 'Vitals are strong again. Good.', 'Health is climbing. Threat decreasing.', 'Recovery is nearly complete.', 'Health is back up. Continuing the mission.', 'The trend is good. Keep recovering.', 'Vitals are improving steadily.', 'Health is restored to safe levels.', 'Recovery confirmed. All systems nominal.', 'HP is rising. We are back in the fight.'},
        ko = {'Party member down. Revival required.', 'KO confirmed. Initiating revival protocol.', 'We have a casualty. Begin recovery.', 'Member incapacitated. Shift to recovery mode.', 'Fallen ally detected. Revival is the priority now.', 'Combat effectiveness reduced. Revive first.', 'One member down. Recovery takes precedence.', 'KO noted. All efforts to revival.', 'We lost one. Get them back up.', 'Incapacitation alert. Recovery protocol engaged.', 'Member is down. Focus on revival.', 'Casualty on the field. Revival underway.', 'Party strength reduced. Revive immediately.', 'Fallen member confirmed. Begin revival.', 'We need that member back. Reviving now.', 'KO status. Recovery is now the mission.', 'One down. Revival protocol active.', 'Member incapacitated. Reallocate to recovery.', 'We have a casualty. Revival is underway.', 'We are one member short. Revive them.', 'Fallen ally. Revival takes priority over combat.', 'KO detected. Switch to recovery posture.', 'Member down. Do not leave them.', 'Incapacitation confirmed. Recovery is underway.', 'We have lost a member. Bring them back.', 'Casualty in the party. Revival first.', 'One member incapacitated. Recovery mode on.', 'Fallen member. Revival sequence started.', 'KO. Revival is now the objective.', 'One of ours is down. Recovery is running.', 'We need a revival. Immediately.', 'Casualty confirmed. All focus on revival.', 'One ally down. Get them up.', 'Incapacitation. Revival is the priority.', 'Member fallen. Recovery efforts underway.', 'KO confirmed. Revival is in progress.', 'We are down one. Revive and regroup.', 'Fallen ally detected. Recovery initiated.', 'Casualty. Revival protocol engaged.', 'One member is down. Our mission is revival now.'},
        target = {'We have our mark. Engaging now.', 'Studying the enemy. Stand by.', 'New target confirmed. Engaging.', 'The mark is set. Moving forward.', 'Target identified. Tracking.', 'Enemy in sight. Focusing.', 'We have eyes on it. Watching.', 'New hostile designated. Engaging.', 'Target confirmed. Assessing threat.', 'Enemy targeted. Analyzing.', 'Locked on. Moving forward.', 'New target in range. Engaging.', 'Target designated. Tracking status.', 'Enemy identified. Focusing fire.', 'Target acquired. Awaiting engagement.', 'New target locked. Proceeding.', 'Confirmed hostile. Keeping watch.', 'Enemy in range. Target set.', 'Target designated. Engaging now.', 'New hostile acquired. Tracking.', 'Target locked. Assessment complete.', 'Enemy confirmed. Target set.', 'Target acquired. Initiating analysis.', 'New target identified. Engaging.', 'Target designated. Status tracked.', 'Enemy in sight. Target confirmed.', 'Locked on. Time to fight.', 'New hostile in range. Target set.', 'Target confirmed. Proceeding to engage.', 'Enemy targeted. Tracking movement.', 'Target acquired. Monitoring threat.', 'New target designated. Engaging.', 'Eyes on the mark. Focusing.', 'Enemy identified. Target confirmed.', 'Target acquired. Assessment underway.', 'New hostile designated. Tracking.', 'Target confirmed. Engaging now.', 'Enemy in sight. Target locked.', 'Target designated. Analysis complete.', 'A new mark is set. Proceeding.'},
        kill = {'Target eliminated. Threat gone.', 'Hostile neutralized. Area clear.', 'The threat is gone. Proceed.', 'Objective complete. Next target.', 'The target is down for good. Moving on.', 'Target down. Threat eliminated.', 'Hostile destroyed. Area secure.', 'Threat neutralized. Status clear.', 'Target eliminated. Awaiting orders.', 'Hostile down. Proceed to next.', 'Target destroyed. All clear.', 'Threat removed. Ready for next.', 'Objective achieved. Moving on.', 'Target eliminated. Combat over.', 'The hostile is down. Standing by.', 'Target down. Threat resolved.', 'Threat eliminated. Proceed.', 'The objective is done. Standing by.', 'Target destroyed. Ready.', 'Hostile down. Threat gone.', 'Target eliminated. Status nominal.', 'Threat removed. Area secure.', 'The hostile is finished. Moving on.', 'Target down. Objective complete.', 'Threat eliminated. All clear.', 'Target destroyed. Awaiting orders.', 'Hostile down. Area clear.', 'Objective complete. Threat gone.', 'Target eliminated. Ready for next.', 'Threat neutralized. Proceed.', 'Target down. Moving to next.', 'Hostile destroyed. Threat gone.', 'Objective achieved. Standing by.', 'That target is gone. Next.', 'Threat removed. Status clear.', 'Hostile down. Awaiting next.', 'Target destroyed. Threat gone.', 'Objective complete. All clear.', 'Target down. Area secure.', 'Hostile neutralized. Combat over.'},
        levelup = {'Level up confirmed. Combat capability increased.', 'New level attained. Stats improved.', 'Level gained. Threat assessment updated.', 'Power increase logged. Proceed.', 'Level up. Stronger than before.', 'New rank reached. Efficiency up.', 'Level gained. New abilities available.', 'Advancement confirmed. Ready for harder targets.', 'Level up. Output increased.', 'Growth logged. Combat readiness improved.', 'New level. Stronger. Ready.', 'Level up confirmed. Continue mission.'},
        longidle = {'No hostiles for five minutes. Sector quiet.', 'Extended quiet. No movement detected.', 'Five minutes without contact. Watch continues.', 'Area remains clear. No change in status.', 'No threats nearby. Standing by.', 'Long quiet stretch. Monitoring continues.', 'No hostiles seen for some time. Standing by.', 'Sector silent. No activity logged.', 'Silence holding. Awaiting next target.', 'No contact for five minutes. All clear.', 'Prolonged calm. Sensors show nothing.', 'Still no hostiles. Position held.'},
        longfight = {'Long engagement ended. All hostiles down.', 'Forty-five seconds plus. Hard fight. We endured.', 'Extended combat concluded. Vitals steady.', 'Tough target. It took longer than projected.', 'Prolonged fight over. Damage sustained, mission done.', 'That one resisted. We outlasted it.', 'Long battle finished. Readiness reduced, morale steady.', 'Extended engagement. It is over. Recovering now.', 'Hard fought. Long fight. We prevailed.', 'That target took time. We took it down.', 'Prolonged combat ended. Sector clear.', 'Long fight concluded. Standing by for recovery.'},
    },
    Playful = {
        engage = {'Another fight? I was just getting comfortable.', 'Right, let us go bother that one.', 'Time to sing and swing. Let us go.', 'Oh good, a fight. I was getting bored.', 'Let us make this one quick and flashy.', 'Here we go. Try to look impressive.', 'A new challenger appears. How exciting.', 'Time to earn our keep. Let us go.', 'I hope this one appreciates good music.', 'Let us dance. The foe leads, unfortunately.', 'Another day, another dramatic entrance.', 'I was born ready. Mostly.', 'Let us show this one our best moves.', 'Time to turn up the volume.', 'Oh, it wants to fight? How rude. Let us oblige.', 'Let us go say hello. With swords.', 'I do love a good opening number.', 'Here comes the fun part. Probably.', 'Let us cause a little chaos. Fun chaos.', 'A fight! My favorite kind of cardio.', 'Time to put on a show. Curtain up.', 'I have a song for this exact occasion.', 'Let us go. The foe is waiting, impatiently.', 'Another one? They just keep coming.', 'I will handle the music. You handle the hitting.', 'Let us turn this into a performance.', 'Oh good, more practice for my battle ballad.', 'Time to shine. Or at least sparkle a little.', 'Let us go introduce ourselves. Loudly.', 'I have been waiting all day for this.', 'A new foe! Let us give it a warm welcome.', 'Let us make this look easy. Or at least fun.', 'Here we go again. Same song, new verse.', 'I do hope this one likes encores.', 'Time to play. Literally. I play an instrument.', 'Let us go. Adventure waits for no bard.', 'Another fight, another story to tell later.', 'I am ready. Are you ready? Too late, let us go.', 'Let us show them how a bard fights.', 'Onward! The music demands it.'},
        idle = {'Well, that was dramatic. I loved it.', 'We survived. Again. I am getting good at this.', 'That was fun. Let us do it again. Later. Maybe.', 'All done. Who is next? Anyone? No?', 'I call that a solid performance.', 'That went well. I barely broke a sweat.', 'We are still here. That is the important part.', 'A round of applause for us, please.', 'That was exciting. My heart is still racing.', 'Victory! I will take a bow later.', 'We did it. High five? No? Fine.', 'That was a workout. I need a snack.', 'All clear. Time for a quick breather.', 'I think we looked great out there.', 'Another win for the history books.', 'That was easy. Suspiciously easy.', 'We make a great team. Obviously.', 'Done and done. What is next on the list?', 'I am going to hum our victory tune now.', 'That was a lot. But we handled it.', 'We are unstoppable. Mostly. Today, anyway.', 'A flawless victory. Well, nearly flawless.', 'That was fun. I want an encore.', 'We did it! Somebody write this down.', 'All quiet now. My favorite sound.', 'That was a good fight. I enjoyed it.', 'We survived another one. Cheers to us.', 'I am taking a bow. You should too.', 'That went better than expected. Nice.', 'Victory tastes sweet. Like a good rest.', 'We did that. All of that. Us.', 'That was intense. I need a minute.', 'Another foe down. We are on a roll.', 'I think that deserves a song. Oh wait, I am the song.', 'All done. That was almost too easy.', 'We are all here and mostly unharmed. I call that a win.', 'That was a performance worth remembering.', 'Done! Let us find the next adventure.', 'I am proud of us. Very proud.', 'That was great. Let us do it again sometime.'},
        low = {'Ouch. That one actually stung.', 'Your HP is dropping. That is not ideal.', 'Hey, that hurt! Let us be careful.', 'You are looking a bit battered. Take it easy.', 'That was a big hit. Maybe dodge next time?', 'Your health is getting low. Not a fan.', 'Oof. That one left a mark.', 'You are hurt. Let us slow down a bit.', 'That was not fun. Let us avoid more of that.', 'Your HP is halfway gone. Yikes.', 'I think you need a bandage. Or ten.', 'That hit was rude. Very rude.', 'You are looking rough. Take a breather.', 'Okay, that was too much. Let us regroup.', 'Your health bar is giving me anxiety.', 'That was a lot of damage. Slow down.', 'You are bleeding. That is not part of the plan.', 'I did not like that hit. Not one bit.', 'Your HP is dropping fast. Careful now.', 'That was painful to watch. Are you okay?', 'You are taking a beating. Let us fix that.', 'I think the foe is winning this round. Let us change that.', 'Your health is low. Time for a tactical pause.', 'Ouch ouch ouch. That was three ouches.', 'You are hurt. I am officially worried.', 'That hit was uncalled for. Let us retaliate carefully.', 'Your HP is not looking great. Just saying.', 'I think you should dodge more. Just a thought.', 'You are looking a little squished. Take care.', 'That was a heavy blow. Let us recover.', 'Your health is slipping. Let us be smart.', 'I am not loving this damage. Let us heal up.', 'You are hurt, and I am concerned. Heal up.', 'That was a nasty one. Let us take a step back.', 'Your HP is half gone. That is half too much.', 'I think we need a breather. And maybe a potion.', 'You are taking too many hits. My nerves cannot take it.', 'That hurt. Let us not do that again.', 'Your health is dropping. I am keeping score, and it is bad.', 'Okay, new plan: less getting hit, more winning.'},
        critical = {'Whoa whoa whoa! Your HP is almost gone!', 'That is a very small health bar. Very small!', 'Okay, this is officially an emergency!', 'Your HP is in the danger zone! Big time!', 'We need healing. Like, right now!', 'That health bar is basically a rumor at this point.', 'Red alert! Your HP is nearly gone!', 'Okay, no more heroics! Fall back!', 'Your HP is so low I can barely see it!', 'This is bad. This is very, very bad.', 'Heal! Dodge! Run! Anything! Just survive!', 'Your health is hanging by a thread. A thin one.', 'Okay, panic time. Just a little panic.', 'That was way too close. Way too close.', 'Your HP is critical! This is not a drill!', 'I can count your HP on one hand. Not good.', 'We are in trouble. Big trouble.', 'Your health is almost gone. Do something!', 'Okay, this is the part where we run away. A little.', 'That health bar is scaring me. Heal up!', 'Emergency! Your HP is nearly zero!', 'I am not panicking. You are panicking. Heal!', 'Your HP is so low it is practically a suggestion.', 'This is the worst time to be brave. Fall back!', 'Okay, that was terrifying. Let us not repeat it.', 'Your health is critical! I am officially worried!', 'We need a miracle. Or a potion. A potion works.', 'That was almost the end. Almost!', 'Your HP is in single digits territory. Run!', 'I am going to need you to not die, please.', 'Red flag! Red flag! Your HP is gone!', 'Okay, deep breaths. And healing. Mostly healing.', 'Your health is gone. Like, actually gone.', 'This is a five-alarm emergency. Heal now!', 'I did not sign up for this level of danger.', 'Your HP is critical. I repeat, critical!', 'Okay, that was too close for comfort. Way too close.', 'We are one hit from disaster. One hit!', 'Your health is nearly zero. This is fine. It is fine. It is not fine.', 'Heal now! I will hold the foe off! Probably!'},
        recover = {'Your HP is coming back. Phew.', 'That is more like it. Looking good.', 'You are healing up. Excellent.', 'Crisis averted. For now, anyway.', 'Your health is back. What a relief.', 'That was scary. But you are better now.', 'HP rising. I can breathe again.', 'You are looking healthier. Thank goodness.', 'That was close. But look at you now.', 'Your HP is climbing. Music to my ears.', 'You are back on your feet. Bravo.', 'Health restored. Let us keep it that way.', 'That is better. Much, much better.', 'You are healing nicely. Keep it up.', 'Phew. That was a close one.', 'Your HP is looking good again. Nice.', 'You are back. I knew you would be.', 'That was a scare. But you are fine now.', 'Health is returning. Crisis over.', 'You are looking strong again. Great.', 'HP up. Worries down. That is the deal.', 'You are recovering well. I am relieved.', 'That was intense. But you made it.', 'Your health is back. Let us not lose it again.', 'Looking good. Let us keep it that way.', 'You are healing up fast. Impressive.', 'That was a close call. Glad you are okay.', 'HP rising. My nerves are calming down.', 'You are back to full-ish. Good enough.', 'Health is back. Let us celebrate quietly.', 'You are looking like yourself again. Good.', 'That was scary, but you pulled through.', 'HP climbing. I approve. Strongly.', 'You are better now. Let us move on.', 'Recovery complete. Mostly. Good enough.', 'Your health is back. Let us be careful this time.', 'That was a wild ride. You are okay now.', 'HP up. Crisis down. Perfect.', 'You are healing. I can stop worrying. Mostly.', 'Looking much better. Let us keep it that way.'},
        ko = {'Well, that was dramatic. Even for us.', 'You are down. I am not even surprised. A little.', 'Okay, that was not part of the plan.', 'You fell down. I will get you back up.', 'That was a spectacular fall. Impressive, really.', 'Down you go. Up you come. That is the deal.', 'Well, that happened. Let us fix it.', 'You are taking a nap at a bad time.', 'I will revive you. This is not the end.', 'That was unexpected. Even for me.', 'You are down, but I have got a plan.', 'Oops. That was not supposed to happen.', 'Take a quick nap. I will handle the rest.', 'You fell. I will pick you up. Literally.', 'That was a rough one. Let us try again.', 'Down, but not out. I refuse to accept it.', 'You are resting. I will wake you soon.', 'Well, that was a plot twist.', 'I will get you back on your feet. Promise.', 'That was not ideal. Let us fix it.', 'You are down. I am on it. Do not worry.', 'A tactical nap. I like it. Let us revive you.', 'That was a big fall. Are you okay? You are not. I will fix it.', 'You are out cold. I will bring you back.', 'Okay, that was embarrassing. For the foe, I mean. We will win.', 'You are down. But I have seen worse. Probably.', 'Rest now. I will do the heavy lifting.', 'That was quite the tumble. Up you get.', 'You fell down. It happens to the best of us.', 'I will revive you. Just give me a moment.', 'Down you go. But not for long.', 'That was not in the script. Let us improvise.', 'You are taking a break. I will cover you.', 'Well, that was a surprise. Let us fix it.', 'You are down. I am not worried. Mostly.', 'A little nap in the middle of battle. Bold.', 'I will get you up. That is my job.', 'You fell. I will catch you. After I revive you.', 'That was a hard hit. Let us get you back.', 'Down, but never out. I will make sure of it.'},
        target = {'That one. It looks like trouble. Good.', 'New target. Let us see what it can do.', 'That one looks interesting. In a bad way.', 'Found it. Let us go say hello.', 'That one has trouble written all over it.', 'Target picked. Let us make it count.', 'That one looks like a good time. Let us fight it.', 'A new foe. The plan is still to win.', 'That one. Definitely that one.', 'I have my eye on that one too.', 'That looks like our next adventure.', 'Target acquired. Let us have some fun.', 'That one is asking for it. Let us oblige.', 'New target. I like the look of that one. Not really.', 'That one looks tough. Perfect.', 'Found our next challenger. Let us go.', 'That one. It is giving me a look.', 'Target selected. Time to play.', 'That one looks like a good story later.', 'New target. Let us make it a quick one.', 'That one. I have a good feeling. A bad good feeling.', 'Target picked. Let us do this.', 'That one looks like it wants a fight. Good.', 'Found it. Let us go get it.', 'That one is our next big moment.', 'Target locked. Let us have at it.', 'That one looks spicy. I like it.', 'A fresh foe. Same energy as before.', 'That one. Let us show it our moves.', 'I see it. Let us go introduce ourselves.', 'That one looks like trouble. My favorite kind.', 'Target acquired. Let the fun begin.', 'That one is next. I can feel it.', 'New target. Let us make it memorable.', 'That one seems ready. Good. So are we.', 'There is our troublemaker. Back for more.', 'That one. Time for another performance.', 'Target picked. Let us put on a show.', 'That one looks entertaining. Dangerously entertaining.', 'New target. Let us go. Adventure awaits.'},
        kill = {'One down. That was fun.', 'Got it. Who is next?', 'That one is history. Nice.', 'Down it goes. Beautiful.', 'Another one bites the dust. Literally.', 'That was easy. Too easy. I love it.', 'One less foe to worry about. Yay.', 'Target down. I am taking a bow.', 'That was a great hit. Encore?', 'Down. Done. Next, please.', 'That one is finished. Onward.', 'Nice work. That was satisfying.', 'One down, many to go. Probably.', 'That was a clean finish. Bravo.', 'Gotcha. Who is next on the list?', 'That one is finished. On to the next.', 'Perfect. That was textbook.', 'Down it goes. I love this part.', 'Another victory. I am counting them.', 'That was fun. Let us do it again.', 'One down. That felt good.', 'Target eliminated. With style.', 'That one is gone. Poof.', 'Nice. That felt really good.', 'Down. That was a good one.', 'That was quick. I like quick.', 'One more down. We are on fire.', 'Got it. That was almost too easy.', 'That one is done. What is next?', 'Beautiful. That was a great fight.', 'Down it goes. Another win for us.', 'That was excellent. Truly excellent.', 'One down. Let us keep this going.', 'Target down. I am impressed. With us.', 'That was a solid win. Well done, us.', 'Gotcha. That was fun.', 'One less foe. One more victory.', 'That was great. Let us keep rolling.', 'Down. Done. Next adventure.', 'That one is finished. Encore, please.'},
        levelup = {'Ding! A new level! I heard it from here!', 'Level up! You are officially fancier now!', 'A whole new level! Look at you glow!', 'You leveled up! I knew you had it in you!', 'New level, new tricks! Show them off!', 'Level up! That glow is very flattering on you!', 'You just got stronger! I felt the ground shake! Well, a little!', 'Another level! You are collecting them like songs!', 'Level up! Time for a tiny celebration dance!', 'You grew a level! Somebody bring cake!', 'Level up! You are on a roll today!', 'A new level! The bats should be worried now!'},
        longidle = {'It is so quiet I can hear my own humming.', 'Five minutes of nothing. The bats are shy today.', 'This quiet is getting suspicious. In a cozy way.', 'I have counted the torches twice. Still quiet.', 'No bats, no noise, just us. I like it. Mostly.', 'It is peaceful. Too peaceful. I am bored. A little.', 'I could nap standing up. Do not tell anyone.', 'The tomb is holding its breath. So am I.', 'Quiet, quiet, quiet. I miss the action. A tiny bit.', 'Five minutes with no fight. My feet are getting restless.', 'I am inventing songs about the silence. It is going well.', 'Still quiet. I will hum until something shows up.'},
        longfight = {'Phew! That one took forever! My arms are tired!', 'That fight was long! I need a sit down. And a drink.', 'Finally! That foe just would not quit!', 'That was a marathon! I am exhausted. And thrilled!', 'Whew! That took ages! We did it anyway!', 'That foe was stubborn! We were stubborner! Is that a word? It is now!', 'Long fight! Big win! I need a breather!', 'That one really made us work for it! Worth it!', 'My goodness, that took a while! But we won!', 'That was the longest bat ever! I am so relieved!', 'We outlasted it! I am tired and proud and tired!', 'That fight went on and on! And we won it! Ha!'},
    },
}

-- Combinatorial persona lines: the 960 middles above stay as-is.
-- Each persona x category also gets 12 short openers and 12 short
-- closers. get_random_line picks a random middle, then with ~50%
-- chance prepends an opener and ~50% chance appends a closer,
-- falling back to the middle alone if the result would exceed
-- 90 chars. 40 middles x 13 opener choices x 13 closer choices
-- = 6,760 combinations per category.
Character.PersonaOpeners = {
    Supportive = {
        engage = {'Here we are,', 'Stay with me,', 'All together,', 'Brave heart,', 'I am here,', 'Steady now,', 'Heads high,', 'We go together,', 'Your song guides us,', 'Do not fear,', 'Trust in yourself,', 'Shoulder to shoulder,'},
        idle = {'Beautiful work,', 'Pause a moment,', 'Easy does it,', 'That was wonderful,', 'Rest easy,', 'You did superbly,', 'Calm at last,', 'What a win,', 'Slow down now,', 'Enjoy the calm,', 'You earned this,', 'That was lovely,'},
        low = {'Watch yourself,', 'I spot you,', 'Hang tight,', 'Stay close,', 'You are wounded,', 'Allow me,', 'Easy now,', 'I am keeping watch,', 'Do not worry,', 'Get behind me,', 'Count on me,', 'Be careful,'},
        critical = {'Hold on!', 'Stay close to me!', 'Never give up!', 'I am on my way!', 'Pull back now!', 'Stay alive!', 'Do not drop!', 'I am with you!', 'Get back now!', 'Hold tight!', 'Grip tight!', 'I will save you!'},
        recover = {'There we go,', 'So much better,', 'Look at you,', 'Good, good,', 'Getting better,', 'Better already,', 'Welcome back,', 'Stronger now,', 'Good recovery,', 'Such a relief,', 'See? Better,', 'Keep at it,'},
        ko = {'Oh no,', 'Stay with me,', 'No need to fear,', 'Rest now,', 'I am beside you,', 'Take all the time,', 'Do not fear,', 'I will rescue you,', 'Hold on,', 'You are protected,', 'Shut your eyes,', 'I am holding you,'},
        target = {'I have got it marked,', 'That one,', 'Eyes open,', 'Focus now,', 'Stay sharp,', 'Watch it,', 'Right behind you,', 'There is our target,', 'Careful now,', 'We see it,', 'Stay ready,', 'Together now,'},
        kill = {'What a victory,', 'Beautiful,', 'Well played,', 'Excellent,', 'Wonderful,', 'A fine win,', 'You are splendid,', 'Superb,', 'You were great,', 'That was great,', 'Bravo,', 'Splendid,'},
        levelup = {'A bright star,', 'What growth,', 'Wonderful news,', 'You did it,', 'A new level,', 'Such progress,'},
        longidle = {'Peaceful now,', 'How restful,', 'So much calm,', 'Quiet moments,', 'Listen now,', 'All is still,'},
        longfight = {'What a battle,', 'That was long,', 'You endured,', 'It is done,', 'Such a struggle,', 'Hard fought,'},
    },
    Tactical = {
        engage = {'Threat confirmed.', 'Moving in.', 'Engaging.', 'Hostile ahead.', 'Target set.', 'Combat on.', 'Weapons ready.', 'Formation set.', 'Proceeding.', 'Assessment done.', 'Ready.', 'Go.'},
        idle = {'Area clear.', 'Threat gone.', 'All nominal.', 'On standby.', 'All clear.', 'Zero hostiles.', 'Fight over.', 'Ready.', 'Monitoring.', 'Holding.', 'Secure.', 'Awaiting orders.'},
        low = {'Warning.', 'Vitals low.', 'Caution.', 'Damage logged.', 'Health falling.', 'Defense up.', 'Watch vitals.', 'Threat high.', 'Half health.', 'Stay alert.', 'Risk rising.', 'Adjust.'},
        critical = {'Critical.', 'Emergency.', 'Retreat now.', 'Danger.', 'Step back.', 'Withdraw.', 'Disengage.', 'Stabilize.', 'Cover now.', 'Vitals critical.', 'Abort.', 'Evacuate.'},
        recover = {'Recovering.', 'Vitals up.', 'Vitals rising.', 'Stabilizing.', 'Improving.', 'Trend good.', 'Back online.', 'Status better.', 'HP climbing.', 'Resuming.', 'Steady.', 'Good.'},
        ko = {'Casualty.', 'Ally down.', 'KO noted.', 'Revival needed.', 'One down.', 'Incapacitated.', 'Recovery stance.', 'Fallen.', 'Revive now.', 'Priority shift.', 'Casualty logged.', 'Down one.'},
        target = {'Mark confirmed.', 'Locked.', 'Confirmed.', 'Tracking.', 'Mark set.', 'Watching.', 'Hostile ID.', 'Acquired.', 'Designated.', 'Visible.', 'New mark.', 'Focus.'},
        kill = {'Eliminated.', 'Threat gone.', 'Objective done.', 'Hostile ended.', 'Target finished.', 'Neutralized.', 'Threat ended.', 'Complete.', 'Confirmed kill.', 'Area clear.', 'Done.', 'Next.'},
        levelup = {'Level gained.', 'Growth logged.', 'Advancement.', 'Power up.', 'Rank increased.', 'Upgrade done.'},
        longidle = {'No activity.', 'Zero contact.', 'Sector calm.', 'Watch ongoing.', 'Quiet holding.', 'No motion.'},
        longfight = {'Marathon fight.', 'Extended combat.', 'Hard target.', 'Survived it.', 'Long haul.', 'Stamina test.'},
    },
    Playful = {
        engage = {'Oh joy,', 'Here it is!', 'Time to glow,', 'Let us do this!', 'A fight!', 'Lights, action!', 'My moment!', 'Time to dance,', 'Here comes fun,', 'Ready or not,', 'Showtime!', 'Off we go!'},
        idle = {'Phew!', 'Well now,', 'So much fun,', 'Ta-da!', 'We won!', 'Victory dance?', 'All finished,', 'Breathe now,', 'That was grand,', 'Still alive!', 'Encore?', 'What a show,'},
        low = {'Ouch!', 'Uh oh,', 'Yikes,', 'That smarted!', 'Oof!', 'Hey now,', 'Not good,', 'Careful!', 'Whoa,', 'That stung!', 'Ouch ouch,', 'Hmm,'},
        critical = {'Whoa!', 'Uh oh!', 'Red alert!', 'Panic time!', 'Whoa there!', 'Emergency!', 'Yikes!', 'Oh no!', 'Run!', 'Heal now!', 'Danger!', 'Whoa nelly!'},
        recover = {'Phew!', 'Way better,', 'Crisis done,', 'Look at that!', 'All better,', 'Whew!', 'Back again,', 'Good as new,', 'Relief!', 'Nice,', 'That was tight,', 'We are back,'},
        ko = {'Oops!', 'Well,', 'Uh oh,', 'Down it goes!', 'Oopsie!', 'That was wild,', 'Well now,', 'Oh dear,', 'Tactical nap,', 'Plot twist!', 'Surprise!', 'Hmm,'},
        target = {'That thing!', 'Ooh,', 'Found it!', 'Look!', 'There!', 'That thing,', 'Spotted!', 'Hello there,', 'Aha!', 'Fresh target!', 'Interesting,', 'Let us look,'},
        kill = {'Boom!', 'Got it!', 'Nice!', 'Down one!', 'Poof!', 'Done!', 'Victory!', 'Bullseye!', 'Gotcha!', 'Sweet!', 'Clean!', 'Yes!'},
        levelup = {'Ding ding!', 'Up a level!', 'Woo hoo!', 'Shiny!', 'Fresh level!', 'Hooray!'},
        longidle = {'So quiet,', 'Shh,', 'Still nothing,', 'Yawn,', 'Hush now,', 'So serene,'},
        longfight = {'Exhausting!', 'Finally!', 'Epic fight!', 'That dragged on!', 'Done at last!', 'Long one!'},
    },
}

Character.PersonaClosers = {
    Supportive = {
        engage = {'you can do it!', 'go get them!', 'we are with you!', 'stay strong!', 'you have got it!', 'forward, march!', 'we will do it!', 'make me proud!', 'onward!', 'together!', 'you are set!', 'we will win!'},
        idle = {'rest well!', 'you earned it!', 'take it slow!', 'lovely work!', 'enjoy the peace!', 'easy now!', 'great job!', 'rest now!', 'safe at last!', 'take a breather!', 'good work!', 'safe and sound!'},
        low = {'right beside you!', 'let me aid you!', 'stay safe!', 'no need to fear!', 'I am holding you!', 'mind yourself!', 'hang in there!', 'I will protect you!', 'stick with me!', 'take it slow!', 'you are safe!', 'you are covered!'},
        critical = {'live through this!', 'I have you!', 'hold fast!', 'grip on tight!', 'step back!', 'I am rushing over!', 'do not fade!', 'never surrender!', 'we will rescue you!', 'hang on!', 'be safe!', 'I am beside you!'},
        recover = {'keep it going!', 'healing well!', 'stay strong!', 'nice recovery!', 'you are strong!', 'nice work!', 'stay healthy!', 'looking good!', 'you are here!', 'stay well!', 'I am proud!', 'onward!'},
        ko = {'I will revive you!', 'we will revive you!', 'hang on!', 'I am staying here!', 'rest easy!', 'no fear!', 'I am staying put!', 'you will return!', 'stick with me!', 'in my safe hands!', 'we will raise you up!', 'trust me!'},
        target = {'we have got this!', 'stay keen!', 'keep watching!', 'you can win this!', 'stay alert!', 'I am beside you!', 'we are set!', 'stay steady!', 'you have got this!', 'let us move!', 'we can win this!', 'stay calm!'},
        kill = {'what a fight!', 'so proud!', 'amazing work!', 'onward!', 'fine work!', 'great work!', 'you won!', 'magnificent!', 'take a bow!', 'rest a bit!', 'safe at last!', 'hurrah!'},
        levelup = {'you are growing!', 'keep shining!', 'onward and upward!', 'well earned!', 'so well deserved!', 'you inspire me!'},
        longidle = {'enjoy the hush!', 'calm and cozy!', 'not a sound!', 'a gentle pause!', 'patience, friend!', 'slow and easy!'},
        longfight = {'you stood firm!', 'what a triumph!', 'what a hero!', 'we pulled through!', 'breathe at last!', 'you held strong!'},
    },
    Tactical = {
        engage = {'proceed.', 'stay vigilant.', 'maintain formation.', 'advance.', 'engage.', 'hold position.', 'arms ready.', 'stay sharp.', 'move in.', 'begin.', 'acknowledged.', 'execute.'},
        idle = {'orders awaited.', 'set.', 'clear.', 'move when ready.', 'waiting.', 'nominal.', 'watching.', 'holding fast.', 'safe.', 'next mission.', 'go when ready.', 'done.'},
        low = {'fall back.', 'vigilant.', 'prioritize defense.', 'monitor vitals.', 'beware.', 'hold position.', 'defend.', 'stay sharp.', 'recover first.', 'watch HP.', 'stay safe.', 'adapt.'},
        critical = {'break off.', 'retreat at once.', 'stabilize fast.', 'withdraw now.', 'retreat.', 'take cover.', 'stop.', 'recover.', 'no combat now.', 'stay alive.', 'clear out.', 'now.'},
        recover = {'proceed.', 'status improving.', 'back to it.', 'better.', 'ready.', 'continue.', 'stable.', 'all clear.', 'move on.', 'threat falling.', 'recovered.', 'go.'},
        ko = {'revival sequence.', 'recover first.', 'bring them home.', 'priority: revival.', 'revive them.', 'healing mode.', 'lift them up.', 'mission: revival.', 'focus revival.', 'revive.', 'recover.', 'now.'},
        target = {'engaging.', 'proceed.', 'stay focused.', 'go.', 'track it.', 'monitor.', 'lock on.', 'execute.', 'move in.', 'stay sharp.', 'affirmative.', 'begin.'},
        kill = {'proceed.', 'next one.', 'clear.', 'standing by.', 'objective met.', 'gone.', 'ready.', 'move on.', 'all good.', 'ready for more.', 'finished.', 'go.'},
        levelup = {'capability up.', 'edge gained.', 'numbers up.', 'objectives await.', 'rank up logged.', 'level noted.'},
        longidle = {'sector clear.', 'no change.', 'scan continues.', 'post secure.', 'all quiet.', 'awaiting contact.'},
        longfight = {'target gone.', 'endurance logged.', 'recover now.', 'duty done.', 'outlasted them.', 'standing down.'},
    },
    Playful = {
        engage = {'let us roll!', 'this will be fun!', 'keep up!', 'lights up!', 'let us shine!', 'here we are!', 'onward!', 'playtime!', 'make it flashy!', 'dance time!', 'adventure!', 'go go go!'},
        idle = {'what now?', 'one more!', 'snack time!', 'victory!', 'so fun!', 'bow time!', 'rest up!', 'onward!', 'cheers!', 'great show!', 'what a ride!', 'next!'},
        low = {'be careful!', 'dodge more!', 'heal up!', 'slow down!', 'ow!', 'easy now!', 'watch out!', 'stay safe!', 'eek!', 'it stings!', 'regroup!', 'careful now!'},
        critical = {'flee!', 'heal fast!', 'fall back!', 'survive!', 'panic!', 'dodge!', 'hide!', 'help!', 'retreat!', 'act fast!', 'stay alive!', 'quick!'},
        recover = {'back in action!', 'brand new!', 'onward!', 'sweet!', 'sigh!', 'looking good!', 'we made it!', 'crisis passed!', 'all good!', 'great!', 'relieved!', 'let us go!'},
        ko = {'I will mend it!', 'up you rise!', 'power nap!', 'not over yet!', 'I have you now!', 'rest up!', 'back soon!', 'no worries!', 'we will mend it!', 'up up up!', 'take a nap!', 'I have a plan!'},
        target = {'let us get it!', 'trouble time!', 'have fun!', 'go go go!', 'let us play!', 'game on!', 'here we go!', 'showtime!', 'let us try this!', 'bring it on!', 'let us move!', 'fun time!'},
        kill = {'next victim?', 'encore?', 'so much fun!', 'onward!', 'next!', 'beautiful!', 'nailed it!', 'take a bow!', 'who is first?', 'more!', 'let us go!', 'cheers!'},
        levelup = {'ring the bell!', 'shine on!', 'level up dance!', 'you glow!', 'fancy now!', 'party time!'},
        longidle = {'too quiet!', 'nap time?', 'quiet as mice!', 'boring, huh?', 'so sleepy!', 'still waiting!'},
        longfight = {'that was huge!', 'what a slog!', 'we finished it!', 'so tired!', 'victory at last!', 'that was epic!'},
    },
}

function Character.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Character)

    self.dispose_bag = DisposeBag.new()
    self.party_member_dispose_bags = {}
    self.low_hp_warned = {}
    self.critical_hp_warned = {}
    -- Situational triggers (added for the "act like an AI" work):
    -- last_level tracks the player's job level for the levelup
    -- line; idle_since marks when the current idle stretch
    -- began for the long-idle line; fight_start marks when the
    -- current fight began for the long-fight line.
    self.last_level = nil
    self.idle_since = nil
    self.longidle_said = false
    self.fight_start = nil

    return self
end

function Character:destroy()
    for _, dispose_bag in pairs(self.party_member_dispose_bags) do
        dispose_bag:destroy()
    end
    self.party_member_dispose_bags = {}
    Role.destroy(self)
    self.dispose_bag:destroy()
end

function Character:get_type()
    return "character"
end

function Character:allows_duplicates()
    return false
end

function Character:get_random_line(category)
    local persona_name = state.CharacterPersonaMode.value
    if not Character.Persona[persona_name] then
        persona_name = 'Supportive'
    end
    local lines = Character.Persona[persona_name][category]
    if not lines or #lines == 0 then
        return nil
    end
    local middle = lines[math.random(1, #lines)]
    local line = middle
    local openers = Character.PersonaOpeners and Character.PersonaOpeners[persona_name] and Character.PersonaOpeners[persona_name][category]
    if openers and #openers > 0 and math.random() < 0.5 then
        line = openers[math.random(1, #openers)] .. ' ' .. line
    end
    local closers = Character.PersonaClosers and Character.PersonaClosers[persona_name] and Character.PersonaClosers[persona_name][category]
    if closers and #closers > 0 and math.random() < 0.5 then
        line = line .. ' ' .. closers[math.random(1, #closers)]
    end
    if #line > 90 then
        return middle
    end
    return line
end

-- Emotes performed while fighting. Kept to quick, non-disruptive
-- emotes and fired only at combat transitions (engage/kill/idle),
-- randomly, so they do not spam or interrupt songs and weaponskills.
Character.Emotes = {
    engage = { '/salute', '/bow', '/wave', '/nod' },
    kill = { '/cheer', '/clap', '/laugh', '/dance' },
    idle = { '/sigh', '/stretch', '/wave', '/nod' },
}

function Character:emote(moment, chance)
    if state.AutoCharacterMode.value == 'Off' then
        return
    end
    if not self.action_queue then
        return
    end
    -- chance is a 0-1 probability; default 0.4.
    if math.random() > (chance or 0.4) then
        return
    end
    local emotes = Character.Emotes[moment]
    if not emotes or #emotes == 0 then
        return
    end
    local emote = emotes[math.random(1, #emotes)]
    self.action_queue:push_action(CommandAction.new(0, 0, 0, emote), true)
end

function Character:say(category, throttle_key)
    if state.AutoCharacterMode.value == 'Off' then
        return
    end
    local message = self:get_random_line(category)
    if message then
        -- No forced local-only: the line follows PartyChatMode.
        -- 'Party' sends it to party chat (blue), 'Private' shows
        -- it in the user's own log via addon_message.
        self:get_party():add_to_chat(self:get_party():get_player(), message, throttle_key, 8)
    end
end

-- Periodic check: if the player has been idle for 5 minutes or
-- more, say one long-idle line for this idle stretch (not once
-- per tick, and not at all for the short idle right after a fight,
-- which already has its own 'idle' line).
function Character:tic(new_time, old_time)
    if state.AutoCharacterMode.value == 'Off' then
        return
    end
    local player = self:get_party() and self:get_party():get_player()
    if not player or player:get_status() ~= 'Idle' then
        self.idle_since = nil
        self.longidle_said = false
        return
    end
    if self.idle_since and not self.longidle_said and os.time() - self.idle_since >= 300 then
        self.longidle_said = true
        self:say('longidle', 'character_longidle')
    end
end

function Character:on_add()
    Role.on_add(self)

    local player = self:get_party():get_player()

    -- Level up: the 'level up' / 'level down' Windower events are
    -- bridged to on_level_change by the Player object. Only cheer
    -- when the level actually went UP (a level down from sync
    -- is not a celebration).
    local player_info = windower.ffxi.get_player and windower.ffxi.get_player()
    if player_info and player_info.main_job_level then
        self.last_level = player_info.main_job_level
    end
    self.dispose_bag:add(player:on_level_change():addAction(function(_, new_level)
        local old_level = self.last_level
        self.last_level = new_level
        if old_level and new_level and new_level > old_level then
            self:say('levelup', 'character_levelup')
        end
    end), player:on_level_change())

    self.dispose_bag:add(player:on_status_change():addAction(function(_, new_status, old_status)
        if new_status == 'Engaged' and old_status ~= 'Engaged' then
            self.fight_start = os.time()
            self.idle_since = nil
            self.longidle_said = false
            self:say('engage', 'character_engage')
            -- No engage emote: it goes through the action queue
            -- and can delay the follow-up debuff song (Requiem
            -- VII) after the Elegy claim, which lets GearSwap's
            -- tp_retry fire in the gap and flicker TP gear on.
            -- Kill and idle emotes still fire; they do not
            -- land in the middle of a song sequence.
        elseif new_status == 'Idle' and old_status == 'Engaged' then
            self.fight_start = nil
            self.idle_since = os.time()
            self.longidle_said = false
            self:say('idle', 'character_idle')
            self:emote('idle', 0.3)
        elseif new_status == 'Dead' and old_status ~= 'Dead' then
            self:say('ko', 'character_ko')
        end
    end), player:on_status_change())

    self.dispose_bag:add(player:on_target_change():addAction(function(_, new_target_index, old_target_index)
        if new_target_index and new_target_index ~= old_target_index then
            self:say('target', 'character_target')
        elseif not new_target_index and old_target_index and self:get_party():get_player():get_status() == 'Engaged' then
            -- Target cleared while still engaged: the mob died.
            -- A fight that dragged on for 45s or more was a hard
            -- one; say the long-fight line instead of the usual
            -- short kill line.
            local fight_duration = self.fight_start and (os.time() - self.fight_start) or 0
            self.fight_start = nil
            if fight_duration >= 45 then
                self:say('longfight', 'character_longfight')
            else
                self:say('kill', 'character_kill')
            end
            self:emote('kill', 0.5)
        end
    end), player:on_target_change())

    local function watch_party_member(party_member)
        if not party_member then
            return
        end
        local member_id = party_member:get_id()
        if not member_id or self.party_member_dispose_bags[member_id] then
            return
        end
        local member_name = party_member:get_name() or tostring(member_id)
        self.low_hp_warned[member_id] = false
        self.critical_hp_warned[member_id] = false

        local dispose_bag = DisposeBag.new()
        self.party_member_dispose_bags[member_id] = dispose_bag
        local hp_change = party_member:on_hp_change()
        dispose_bag:add(hp_change:addAction(function(_, hpp)
            if state.AutoCharacterMode.value == 'Off' then
                return
            end
            if hpp <= 25 and not self.critical_hp_warned[member_id] then
                self.critical_hp_warned[member_id] = true
                -- Critical implies low: without this the next HP tick below
                -- 25% falls through to the low branch and says a second line
                -- for the same dip.
                self.low_hp_warned[member_id] = true
                self:say('critical', 'character_critical_' .. member_name)
            elseif hpp <= 50 and not self.low_hp_warned[member_id] then
                self.low_hp_warned[member_id] = true
                self:say('low', 'character_low_' .. member_name)
            elseif hpp > 60 then
                local was_low = self.low_hp_warned[member_id] or self.critical_hp_warned[member_id]
                self.low_hp_warned[member_id] = false
                self.critical_hp_warned[member_id] = false
                if was_low then
                    self:say('recover', 'character_recover_' .. member_name)
                end
            end
        end), hp_change)
    end

    local function unwatch_party_member(party_member)
        if not party_member then
            return
        end
        local member_id = party_member:get_id()
        local dispose_bag = self.party_member_dispose_bags[member_id]
        if dispose_bag then
            dispose_bag:destroy()
            self.party_member_dispose_bags[member_id] = nil
        end
        self.low_hp_warned[member_id] = nil
        self.critical_hp_warned[member_id] = nil
    end

    for party in self:get_alliance():get_parties():it() do
        for party_member in party:get_party_members(true):it() do
            watch_party_member(party_member)
        end

        self.dispose_bag:add(party:on_party_member_added():addAction(watch_party_member), party:on_party_member_added())
        self.dispose_bag:add(party:on_party_member_removed():addAction(unwatch_party_member), party:on_party_member_removed())
    end
end

return Character
