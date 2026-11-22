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
        engage = {'No introductions. The {mob} already looks scared.', 'That {mob} just met its biggest fan. Me. Armed.', 'Sword, song, and too much confidence. That is me.', 'That {mob} picked a fight with a bard. Bold. Foolish.', 'That {mob} is about to get my worst review ever.', 'Some bards sing of heroes. I sing while being one.', 'That {mob} thinks it is scary. Cute. Watch this.', 'I came for quiet. Found a {mob} with opinions.', 'That {mob} will learn: my songs are warnings.', 'No luck needed. I have a sword and a soundtrack.', 'That {mob} is in my way. That is its whole story.', 'Quick fight. The {mob} has somewhere to be. Down.', 'A {mob}, a bard. One of us leaves in style.', 'I have a song for this. It is called Ouch, Bat.', 'That {mob} is about to be the verse nobody remembers.', 'I am the hero. The {mob} is the cautionary tale.', 'Time to turn this {mob} into a footnote in my legend.', 'That {mob} speaks fear. I speak fabulous.', 'I sing, I swing, I look great doing both.', 'That {mob} volunteered for my new song. Short one.', 'I have faced worse. Also bats. Same thing.', 'The {mob} wants a fight. I want an audience. I win.', 'Armed, loud, and right. Let us begin.', 'Run, {mob}, or be a funny story later.', 'I do not chase bats. They chase bad decisions.', 'My stage. The {mob} has no ticket. It pays anyway.', 'One hit and that {mob} starts a fan club. For me.', 'That {mob} will learn my sword has a punchline.', 'Not just a bard. A bard with a grudge and a groove.', 'Some heroes brood. I quip. The bats hate both.', 'That {mob} looks tough. I look tougher. And funnier.', 'I will write a ballad about this {mob}. Very short.', 'The tomb is quiet. I am about to fix that. Loudly.', 'That {mob} is the opening act. I am the whole show.', 'My plan: sing, swing, win. In that order.', 'That {mob} is outmatched, outclassed, and out of luck.', 'I never miss. Well, almost never. Today, never.', 'That {mob} thinks this is its tomb. It is mine now.', 'Loud, sharp, impossible to ignore. That is me.', 'Can that {mob} take a joke? And a sword? Let us see.', 'I brought a sword, a song, and zero fear.', 'Time to fight. I already wrote the victory song.', 'A hero walks in. The foe did not RSVP. Too bad.', 'My entrance is the best part. Fight is the encore.', 'I fight with steel, songs, and excellent timing.', 'Somebody cue the music. Oh wait. That is me.', 'I am here, I am loud, and I am winning.', 'This fight is about to be my favorite anecdote.', 'Watch closely. I only do this once. Per foe.', 'A new challenger. My sword is already bored.'},
        idle = {'Flawless victory. I am ignoring the flaws.', 'We won. Full credit to me. Shared blame to us.', 'I fought brilliantly. The bats did not.', 'Another win. My autobiography grows daily.', 'I did not carry the team. I am just implying it.', 'That fight was easy. I say that now that it is over.', 'Victory looks good on me. Everything does.', 'Hazard pay and applause, please. Mostly applause.', 'We survived. I am as surprised as the bats are.', 'A masterpiece. I am the masterpiece. Obviously.', 'I am humble. Extremely humble. About my greatness.', 'Another {mob} down. My legend is a whole paragraph.', 'No sweat broken. A {mob} broken. Same energy.', 'That was fun. I am fun. Coincidence? I think not.', 'We are unstoppable. I decided this. It is official.', 'I will tell this story at every tavern. Twice.', 'That fight had drama, action, and me. Mostly me.', 'I am the hero this tomb deserves. And the one it got.', 'Victory is sweet. I am sweeter. The bats are sour.', 'Thanks to my sword, my songs, and myself.', 'That was almost too easy. I love almost too easy.', 'We won again. I am out of modest things to say.', 'A legend in my own mind. The bats agree. They must.', 'That {mob} never stood a chance. I did. I took it.', 'Taking a bow. The tomb is my audience. Thrilled.', 'We did it. Mostly me. The Trusts helped. A little.', 'My best fight yet. Until the next one. Obviously.', 'Exhausted, victorious, still extremely charming.', 'Bats, surrender now. Save everyone the trouble.', 'Fought, sang, conquered. In that order. Mostly.', 'Another victory. I collect them like compliments.', 'A close one. I planned it that way. For drama.', 'I am the star. The Trusts are my backup band.', 'We won. I am already writing the song. It is about me.', 'That fight was a gift. I gave it to myself.', 'Not tired. Theatrically winded. Big difference.', 'The tomb is quiet. My ego is loud. Balance restored.', 'We did that. I did that. We all did that. Mostly me.', 'That was great. I am great. Let us do it again soon.', 'Winning is my favorite hobby. After singing.'},
        low = {'My HP is dropping. My dignity is dropping faster.', 'That {mob} hit me. I take that personally.', 'I am hurt. This was not in my five-year plan.', 'Health bar shrinking. Ego refuses to shrink.', 'Rude. I am writing an angry song about it.', 'Taking damage. Call my agent. And a healer.', 'HP low. Confidence still suspiciously high.', 'That {mob} just hit the star of the show. The nerve.', 'Bleeding. Very dramatically. Award-worthy bleeding.', 'Somebody heal me. I am too fabulous to faint.', 'That hit was uncalled for. I am calling a healer.', 'My health is fading. My jokes are not. Priorities.', 'Took a hit. Pride took a bigger one. Heal both.', 'That {mob} owes me an apology. And a potion.', 'Hurt, graceful, and complaining loudly.', 'HP bar half empty. Glass half full. Of pain.', 'That was a cheap shot. I only do expensive shots.', 'Need healing. And maybe a new agent. Healing first.', 'Health low. Wit still sharp. The {mob} is doomed.', 'That {mob} hit me right in the punchline.', 'In pain. The hero struggles here. Briefly.', 'Stop that {mob}. It is ruining my good looks.', 'Wounded. My songs are wounded too. Sad songs now.', 'That hit knocked the tune out of me. I have spares.', 'HP dropping like a bad review. Fast and unfair.', 'Hurt, but funnier than the {mob}. Small victory.', 'That {mob} is winning. I refuse to let it enjoy that.', 'Need a potion. And a minute. And an apology.', 'My health is low. My drama is high. It balances out.', 'That was not a love tap. That was a lawsuit.', 'I am taking hits like a drum. A drum with feelings.', 'My HP is fading. My spotlight is not. Heal me.', 'That {mob} hit me so hard I forgot the chorus.', 'I am half dead and still the funniest one here.', 'Somebody heal the hero. The hero is me. Obviously.', 'My health bar is vanishing. Bring it back.', 'That hurt. I am going to bill the {mob} for damages.', 'In pain. But my one-liners are painless. Mostly.', 'My HP is low. My comeback is loaded. Heal me first.', 'That {mob} hit me. I hit back. With jokes. And steel.'},
        critical = {'HP gone. Save the comedian before the tragedy.', 'I am one hit from a very dramatic death scene.', 'This is bad. I am narrating my own downfall. Help.', 'My health bar is a rumor. A tiny, unfunny rumor.', 'Heal me or the jokes stop. Nobody wants that.', 'I see the light. A spotlight. Flattered. Help.', 'My HP is so low it qualifies as a rounding error.', 'The hero almost dies here. Emphasis on almost.', 'I am running on fumes, high notes, and pure spite.', 'Heal now or this becomes a tragedy. I do comedies.', 'Health hanging by a thread. A very funny thread.', 'In danger. Also hilarious. Save the hilarious one.', 'Somebody catch me. I fall with style. And speed.', 'My HP is critical. My timing is terrible. Heal me.', 'About to faint. All my sides are good sides.', 'This is an emergency. I am the emergency. Fix me.', 'Healer, potion, better plan. In that order.', 'Nearly dead and still the wittiest one here.', 'Health bar blinked out. I am blinking back. Help.', 'A bard on the edge. The edge is very high. Help.', 'This is bad. Really bad. Still joking. Heal me.', 'HP lower than my standards. My standards are low.', 'Going down like a bad joke. Save me first.', 'Press every heal button. All of them. At once.', 'I am dying. Beautifully. Hilariously. Help.', 'Health in the basement. The basement is on fire.', 'Five-alarm fire. I am the only firefighter. Help.', 'I am so close to dead I can hear the sad trombone.', 'Heal me now or I haunt this tomb. Annoyingly.', 'HP critical. The funny one is in danger.', 'I am a feather away from a flatline. And a punchline.', 'Save me. I have jokes left to tell. Many jokes.', 'Out of health. Not out of material.', 'Not a drill. A genuine bard emergency. With jokes.', 'My health bar is empty. My panic bar is overflowing.', 'About to be a cautionary tale. I prefer legend.', 'Somebody heal me. I am too funny to die.', 'Death door is asking for my autograph. Help.', 'My HP is gone. My wit remains. Barely. Heal me.', 'Fading fast. Write my epitaph. Make it funny.'},
        recover = {'Health is back. The comedian returns to the stage.', 'I am alive. And still funny. Mostly funny.', 'Crisis over. Back to being the best part here.', 'My HP is climbing. My ego is climbing faster.', 'I am healed. Let us pretend the panic never happened.', 'Close call. I planned the drama. Not the dying.', 'Health restored. The star is back. Show resumes.', 'I am back. Did you miss the jokes? You did. I know.', 'Phew. I am alive and my punchlines survived too.', 'HP back. My near-death is now a funny story.', 'I survived. Write that down. Make it sound heroic.', 'Healing received. Wit restored. Let us go.', 'I am feeling better. The bats should be nervous.', 'Crisis dodged. I dodged it with style. And healing.', 'Health up. Spirits higher. Jokes sharpest.', 'Patched up. Ready for an encore. And a rematch.', 'Terrifying. Fine now. Mostly. Still funny.', 'HP rising. My theme music swells. Dramatically.', 'Back on my feet. The floor sends its regards.', 'Healed. The bats have no idea. Jokes. Swords.', 'Good as new. Better than new. And funnier.', 'HP full. Legend continues. Jokes continue louder.', 'A scare. Over it. Mostly. Do not bring it up.', 'Health back. Reckless again. Carefully. With jokes.', 'Alive. Never speak of it again. Unless it is funny.', 'Patched up. Ready to rock. And roast bats.', 'Recovering beautifully. Like a funny phoenix.', 'HP climbed back. Dignity still climbing. Slowly.', 'Back. The show was paused, not cancelled. Encore.', 'Feeling strong. Feeling brave. Feeling hilarious.', 'Wild ride. Still on it. Healed. And joking.', 'Health good. Mood great. Bats doomed. Jokes ready.', 'Mended. Let us break bats. And tension. With jokes.', 'Crisis over. Applause for the healer. And for me.', 'Whole again. Mostly. Whole enough to be funny.', 'HP back. Songs louder. Jokes sharper.', 'I survived that. I survive everything. With style.', 'Healed up. Fired up. Let us fight. And crack wise.', 'That was intense. I am intense. We match.', 'Back in action. The tomb is not ready.'},
        ko = {'Down. Just an intermission. With floor seating.', 'Fallen. Cue the revival music. And the applause.', 'My dramatic exit. I need a dramatic entrance now.', 'Napping. On the floor. In battle. Wake me.', 'Down I go. Up I come. That is the arrangement.', 'Fainted. Very theatrically. Give me a revival.', 'Plot twist. I usually see those coming.', 'Out cold. The show goes on. Without me. Briefly.', 'Took a bow. A very low bow. On the floor. Help.', 'Down, but my legend is still standing. And joking.', 'Get the bard up. The encore needs me.', 'Resting. Involuntarily. Wake me. The jokes wait.', 'That hit sent me to the floor. Cold. Unimpressed.', 'Down. Not the finale. I refuse that ending.', 'Fainted mid-song. The {mob} has no taste.', 'Wake me. More songs to sing. More bats to roast.', 'Taking a dirt nap. Make it short. I have jokes.', 'Down, not done. I have a second act.', 'Out. Press revival. The funny one is down.', 'Heck of a fall. Catch the next one. Preferably me.', 'Reviewing my life choices down here. Mostly good.', 'Revive me. I am missing all the fun. And applause.', 'Down. The bats are laughing. I am funnier. Wake me.', 'This floor is cold. Lift me up. I am a star.', 'Fainted gracefully. Mostly. Do not ask the bats.', 'Out cold. My songs are still in my head.', 'Down I am. Up I shall be. That is the deal.', 'Took a hit and a nap at once. Efficient. And funny.', 'Wake the bard. The show is not over. Intermission.', 'On the ground. My dramatic low point. Temporary.', 'Fell down. The floor and I are friends. Reluctantly.', 'Unconscious. My ego is awake. And still funny.', 'A knockout. Literally. Knocked out. Still witty.', 'Down. Write a comeback song about me. Catchy.', 'Fainted mid-verse. Revive me. For art.', 'Resting my eyes. And my whole body. Help.', 'Down, dreaming of encores. Wake me for the revival.', 'Out. But I will be back. With better jokes.', 'End of act one. Act two starts now. With a revival.', 'Down. Get me up before the bats start doing comedy.'},
        target = {'That {mob} has main character energy. Mistaken. I do.', 'That {mob} is auditioning to be my next victim.', 'That one owes me money. And an apology.', 'I pick that {mob}. It looks extra defeatable today.', 'That {mob} gives attitude. I give better attitude.', 'Behold, a {mob}. Very punchable, very doomed.', 'That one is trouble. My favorite kind.', 'I chose that {mob}. It does not know yet.', 'That {mob} made eye contact. Bold. Terrible.', 'Target locked. That {mob} becomes a funny story.', 'That one is begging for a beatdown. I accept.', 'That {mob} sees me. It regrets it. Smart one.', 'That {mob} has a face only a mother could love.', 'That {mob}. It is the one. The unlucky one.', 'That {mob} skipped leg day. And arm day. Every day.', 'I have a song for that {mob}. Goodbye, {mob}.', 'That {mob} is my next big number. A very short number.', 'I choose you, {mob}. Let us see what you have got.', 'That one is mine. I called it. Witnessed.', 'That {mob} stands like it owns the tomb. It rents.', 'Target found. Small, flappy, doomed. Mostly doomed.', 'That {mob} stars in my new song. A short song.', 'I like that one. Fight it until it falls.', 'Nervous bat. Good. Nervous bats make great stories.', 'My eye is on that {mob}. Both eyes. And a sword.', 'That one insulted my music. I am offended anyway.', 'Target acquired. That {mob} is funny history.', 'Chosen one. Chosen to be defeated. By me.', 'I see a {mob}. I see a victory. Same thing.', 'That one wants to dance. With my sword. Bad idea.', 'Behold the {mob}. It has no idea. Fun part.', 'My next volunteer. It did not volunteer.', 'I pick that one. Most punchable face.', 'Target spotted. That {mob} lives on borrowed time.', 'That {mob} is asking for it. Happy to oblige.', 'Found our next guest star. A {mob}. Doomed. Applause.', 'That one is giving me a look. A doomed look.', 'New {mob}, same story. It loses. I win.', 'That {mob} is in my spotlight. No escape.', 'I choose that {mob}. Unluckiest {mob} in the tomb.', 'That one is mine. I have already named the song.', 'I choose that one. It looks like a great anecdote.', 'That foe has a face only a bard could roast.', 'Target locked. That one becomes a funny story.', 'Behold the foe. It has no idea. Fun part.', 'That one gives attitude. I give better attitude.', 'My next guest star. Doomed. Applause.', 'I see a foe. I see a victory. Same thing.'},
        kill = {'{mob} down. Get me a trophy. And a microphone.', 'One down. I am already bored. Next. Bigger. Funnier.', 'Standing ovation kill. I stood. I ovated. I won.', '{mob} down. Legend grows. Sword rests. Ego does not.', 'That one is history. I write the songs.', 'Victory. Applause accepted. Silence accepted.', 'That {mob} never had a chance. I made sure of it.', 'Down it goes. Doing a little victory dance.', 'Another {mob} bites the dust. I am the broom.', 'Beautiful. I am beautiful. The bat is dust.', 'One less {mob}. One more song. One more joke.', 'That kill was a masterpiece. I am the artist.', '{mob} defeated. Undefeated. Right now. Ask me later.', 'Quick. I like victories fast, flashy, funny.', 'Down. Done. Next. I am a musical machine.', 'That {mob} is gone. Poof. Like a magic trick. Mine.', 'I did that. Me. The bard. Sword, songs, jokes.', 'Another down. Kill count is fan count. Both growing.', 'Satisfying. Like popping a bubble. A bat bubble.', 'Victory is mine. Sharing it. Generously. With me.', 'That {mob} is finished. I am just getting started.', 'One down. My sword is still humming. It sings.', 'A perfect hit. I am a perfectionist. Obviously.', '{mob} down. Bring me a bigger {mob}. A funny one.', 'That kill deserves an award. I give it to myself.', 'Another victory. I collect them like applause.', 'That {mob} is done. I am done. Next. Bigger {mob}.', 'Down it goes. Barely broke a sweat. Or a joke.', 'That was fun. Time of my life. Literally.', 'One more bat down. My legend is slightly longer.', 'That kill was smooth. Like butter. Bat butter.', 'Victory. Taking a bow. And another. And another.', 'That {mob} is history. I am the future.', 'Down. Suspiciously easy. I love easy.', 'Another bites the dust. I am the dust maker.', 'A great hit. I hit bats. And punchlines.', '{mob} down. Songs lethal. Sword just for show.', 'One down. Who is next? I was born ready.', 'A showstopper. I stopped the show. To kill.', 'Victory again. Running out of ways to be amazing.'},
        levelup = {'Leveled up. The tomb just got funnier. And musical.', 'New level. Officially too powerful for these bats.', 'Level up. Songs louder. Jokes sharper.', 'Stronger now. Bats should file a complaint.', 'New level. Same bard. More fabulous. Funnier.', 'Stronger now. Tell the bats. They will find out.', 'Level up. I feel the power. And the encores.', 'A whole new level. I deserve a parade. And cake.', 'Leveled up mid-fight. Perfect timing. Perfect me.', 'New level unlocked. The bats are in trouble now.', 'Stronger. High notes higher. Jokes sharper.', 'Level up. One step closer to legend. Comedy legend.', 'New level. Officially too powerful for this tomb.', 'Stronger now. The foes should file a complaint.', 'Level up. The whole tomb just got funnier.', 'New level unlocked. The foes are in trouble now.'},
        longidle = {'Five quiet minutes. I wrote three songs about it.', 'So quiet I narrate my own life. Out loud.', 'No bats. Just me, the dark, and my humming.', 'Counted every torch. Twice. Bored. Calm. Funny.', 'Silence so loud I wrote a song about it. A hit.', 'Five minutes, no fight. My feet do a restless dance.', 'Bored. Teaching the Trusts my dance moves. Terrible.', 'Quiet tomb. Inventing a musical. Starring me.', 'Nothing happening. I narrate the nothing. Riveting.', 'Still for five minutes. A personal record. Thrilled.', 'Quiet is cozy. And weird. Mostly cozy. Very quiet.', 'Sleepy standing here. Do not tell the bats.', 'No foes. Just me, the dark, and my humming.', 'Sleepy standing here. Do not tell the foes.'},
        longfight = {'That fight took forever. Jokes survived.', 'Finally. Marathon {mob}. Better jokes: mine.', 'A saga. A {mob} saga. Hero: me. Comic relief: also me.', 'Won. Eventually. I aged a little. Jokes aged well.', 'That {mob} would not quit. Neither would I. I won.', 'Long fight. Longer song. Legendary victory. Mine.', 'That took ages. Exhausted. Victorious. Still funny.', '{mob} fought hard. I fought harder. And funnier.', 'An epic. I am the epic. The {mob} was the footnote.', 'Outlasted it. Tired, proud, thirsty. Still witty.', 'A fight like my best ballad. With more stabbing.', 'Finally done. That {mob} was stubborn. I was stubborner.', 'Finally. Marathon foe. Better jokes: mine.', 'A saga. A foe saga. Hero: me. Comic relief: also me.', 'That foe would not quit. Neither would I. I won.', 'Foe fought hard. I fought harder. And funnier.', 'An epic. I am the epic. The foe was the footnote.', 'Finally done. That foe was stubborn. I was stubborner.'},
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
        engage = {'Curtain up!', 'Showtime, folks!', 'Watch and learn!', 'My big moment!', 'Lights, camera!', 'Big entrance!', 'And... action!', 'Brace yourselves!', 'Here comes trouble!', 'Let the show begin!', 'Time to shine!', 'Drumroll, please!'},
        idle = {'Ta-da, folks!', 'Standing ovation!', 'Curtain call!', 'We did it!', 'Bravo, me!', 'Victory lap!', 'What a show!', 'Encore, please!', 'Flawless!', 'I am a star!', 'Round of applause!', 'That was art!'},
        low = {'My dignity!', 'Rude!', 'Unfair!', 'My hair!', 'Hey, watch it!', 'Not cool!', 'Ouch ouch!', 'Eek!', 'Bad {mob}!', 'So rude!', 'My outfit!', 'So mean!'},
        critical = {'Mayday!', 'Bard emergency!', 'Code red!', 'Save me!', 'Panic!', 'Mayday, folks!', 'Somebody help!', 'Oh no no no!', 'Bard in danger!', 'Mayday mayday!', 'Help, quick!', 'This is bad!'},
        recover = {'Huge relief!', 'Back on stage!', 'Crisis over!', 'What a save!', 'Saved!', 'Second wind!', 'Miracle!', 'Good as new!', 'Back in business!', 'Alive again!', 'Round two!', 'What a relief!'},
        ko = {'Well, oops!', 'Intermission!', 'Twist ending!', 'Timber!', 'Curtain down!', 'Down I go!', 'Nap time!', 'So awkward!', 'Stage exit!', 'My big fall!', 'Not the finale!', 'Took a dive!'},
        target = {'That one!', 'There it is!', 'Look there!', 'Hello, {mob}!', 'Eyes on it!', 'Behold!', 'Target locked!', 'I see you!', 'Right there!', 'Got my eye on it!', 'You there!', 'That {mob}!'},
        kill = {'Bam!', 'Direct hit!', 'Gotcha, {mob}!', 'One less {mob}!', 'Winner!', 'Nailed it!', 'Vanished!', 'Poof, gone!', 'Gone!', 'Perfect hit!', 'Beautiful!', 'Encore!'},
        levelup = {'Ding!', 'Level up!', 'Shiny and new!', 'Power up!', 'Hooray for me!', 'Glow time!'},
        longidle = {'Shh...', 'So quiet...', 'Yawn...', 'Still waiting...', 'Tick tock...', 'Hush...'},
        longfight = {'About time!', 'At last!', 'What a marathon!', 'So exhausting!', 'All done!', 'Whew, that was long!'},
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
        engage = {'rock this tomb!', 'time to shine!', 'the show starts now!', 'bats beware!', 'sing it loud!', 'here comes the fun!', 'watch and learn!', 'this is my stage!', 'bring on the noise!', 'let the music play!', 'it is showtime!', 'make some noise!'},
        idle = {'what a performance!', 'we are amazing!', 'bow, everyone!', 'that was a hit!', 'bravo to us!', 'we stole the show!', 'curtain call!', 'I love this job!', 'on to the next act!', 'applause, please!', 'we are legends!', 'smash hit!'},
        low = {'that was rude!', 'my poor health bar!', 'not in the script!', 'somebody heal me!', 'this is not fair!', 'my hair is ruined!', 'ouch, my everything!', 'that was a low blow!', 'I need a potion!', 'this hurts, folks!', 'bad {mob}, bad!', 'my encore is ruined!'},
        critical = {'heal me now!', 'this is bad!', 'save the bard!', 'I am almost a ghost!', 'emergency, folks!', 'do not let me die!', 'this is not funny!', 'panic stations!', 'my HP is a joke!', 'somebody, anybody!', 'I am fading fast!', 'this is the end? No!'},
        recover = {'back in the game!', 'the show goes on!', 'I am alive again!', 'crisis averted!', 'good as new!', 'ready for more!', 'let us keep going!', 'that was close!', 'health is wealth!', 'feeling fabulous!', 'onward to victory!', 'the bard returns!'},
        ko = {'wake me up soon!', 'this is not the end!', 'revive me, please!', 'intermission, folks!', 'I will be back!', 'do not forget me!', 'the show must go on!', 'I need a revival!', 'down but dreaming!', 'somebody pick me up!', 'encore coming soon!', 'I am just resting!'},
        target = {'that is the one!', 'let us nab it!', 'it is doomed!', 'game on, {mob}!', 'wrong bard, {mob}!', 'glow up time!', 'it is bat time!', 'let us have fun!', 'that {mob} is toast!', 'bring it, {mob}!', 'no chance, {mob}!', 'let us do this!'},
        kill = {'another one down!', 'who is next?', 'that was a blast!', 'I love winning!', 'encore, please!', 'we are unstoppable!', 'bow time, folks!', 'beautiful work!', 'the crowd goes wild!', 'one more, please!', 'victory is sweet!', 'let us keep rolling!'},
        levelup = {'stronger than ever!', 'time to celebrate!', 'the bats are doomed!', 'brighter than ever!', 'I feel powerful!', 'onward to glory!'},
        longidle = {'so very quiet!', 'anybody there?', 'the silence is loud!', 'waiting for action!', 'bored but cozy!', 'tick tock, bats!'},
        longfight = {'what a marathon!', 'we survived it!', 'that took forever!', 'epic victory!', 'never again! Maybe!', 'I need a nap!'},
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
    -- Delayed engage line: set on engage, said by tic() 5s later
    -- (see below). The engage line used to fire the instant the
    -- Bard engaged, right in the Elegy -> Requiem VII window.
    self.engage_line_pending = false
    -- Last target mob name, cached on target change. The kill line
    -- fires when the target clears (the mob died), so by then there
    -- is no target to read the name from; the cache lets the kill
    -- line still know what was just fought.
    self.last_target_name = nil
    -- Shuffled decks of middle indices, one per persona+category
    -- (see draw_middle). Lazily rebuilt; nil-guarded there too.
    self.line_decks = {}

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

-- A line is bat-specific when it mentions a bat as a whole word
-- ("bat" / "bats"). The frontier pattern keeps "battle" and
-- "combat" generic: those are ordinary words, not bat mentions.
local function is_bat_line(line)
    return line and string.find(string.lower(line), '%f[%a]bats?%f[%A]') ~= nil
end

-- The name of the mob being fought, for {mob} lines. Current target
-- first, then the last target seen (the kill line fires after the
-- target clears), else 'foe'. The full name as it appears in game
-- ("Locus Dire Bat"), not a shortened type. Never crashes.
function Character:get_target_mob_name()
    if windower and windower.ffxi and windower.ffxi.get_mob_by_target then
        local ok, mob = pcall(windower.ffxi.get_mob_by_target, 't')
        if ok and mob and mob.name then
            return mob.name
        end
    end
    if self.last_target_name then
        return self.last_target_name
    end
    return 'foe'
end

-- What kind of mob is the player fighting? Returns 'bat' when the
-- target mob's name contains "bat", otherwise 'generic'. The client
-- cannot read a mob's family (server-side only), so the name is the
-- only signal -- the same approach as the mobweak addon. Only the
-- bat-wordplay lines (bat puns, plural "bats") are gated on this;
-- {mob} placeholder lines work on any mob because the real name
-- goes in. Never crashes: no target and no cached name means
-- generic.
function Character:get_target_mob_kind()
    local name = self:get_target_mob_name()
    if name ~= 'foe' and string.find(string.lower(name), 'bat', 1, true) then
        return 'bat'
    end
    return 'generic'
end

-- Draw the next middle from a shuffled deck, so every middle in a
-- category is used once before any repeats, then the deck is
-- reshuffled -- like a shuffled deck of cards. The deck is built
-- from the middles allowed for the current mob kind; when the kind
-- changes (bat to non-bat or vice versa) it is rebuilt from the
-- newly allowed pool. Decks live on the Character object and
-- survive across fights; they are only rebuilt when empty or when
-- the kind changes. Lazily initialized and nil-guarded.
local function draw_middle(self, persona_name, category, lines, kind)
    self.line_decks = self.line_decks or {}
    local by_persona = self.line_decks[persona_name]
    if not by_persona then
        by_persona = {}
        self.line_decks[persona_name] = by_persona
    end
    local deck = by_persona[category]
    if not deck or deck.kind ~= kind or not deck.remaining or #deck.remaining == 0 then
        local allowed = {}
        for i = 1, #lines do
            if kind == 'bat' or not is_bat_line(lines[i]) then
                allowed[#allowed + 1] = i
            end
        end
        if #allowed == 0 then
            return nil
        end
        -- Fisher-Yates shuffle.
        for i = #allowed, 2, -1 do
            local j = math.random(1, i)
            allowed[i], allowed[j] = allowed[j], allowed[i]
        end
        deck = { kind = kind, remaining = allowed }
        by_persona[category] = deck
    end
    local idx = deck.remaining[#deck.remaining]
    deck.remaining[#deck.remaining] = nil
    return lines[idx]
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
    -- Mob-aware pools: on a bat fight the full pool (bat-wordplay +
    -- generic lines) is available; on anything else, bat-specific
    -- lines are filtered out, so no part of the combined line can
    -- mention a bat. Lines with a {mob} placeholder pass the
    -- filter and get the real mob name inserted below, so the same
    -- joke works on every mob.
    local kind = self:get_target_mob_kind()
    -- Middle: drawn from a shuffled deck (see draw_middle), so every
    -- middle in the category is used once before any repeats.
    local middle = draw_middle(self, persona_name, category, lines, kind)
    if not middle then
        return nil
    end
    -- Openers/closers stay random: short fragments that combine with
    -- the middle, so each draw still feels different.
    local function pick(pool)
        if not pool or #pool == 0 then
            return nil
        end
        if kind == 'bat' then
            return pool[math.random(1, #pool)]
        end
        local generic = {}
        for i = 1, #pool do
            if not is_bat_line(pool[i]) then
                generic[#generic + 1] = pool[i]
            end
        end
        if #generic == 0 then
            return nil
        end
        return generic[math.random(1, #generic)]
    end
    -- Insert the real mob name into {mob} lines. Substitute before
    -- the length check, so a line that runs over 90 with a long mob
    -- name falls back to the bare middle, as before. The fallback
    -- middle is substituted too, so a placeholder never leaks
    -- into chat.
    local mob_name = self:get_target_mob_name()
    local function fill(line)
        return (string.gsub(line, '{mob}', function() return mob_name end))
    end
    local line = fill(middle)
    local openers = Character.PersonaOpeners and Character.PersonaOpeners[persona_name] and Character.PersonaOpeners[persona_name][category]
    if openers and #openers > 0 and math.random() < 0.5 then
        local opener = pick(openers)
        if opener then
            line = fill(opener) .. ' ' .. line
        end
    end
    local closers = Character.PersonaClosers and Character.PersonaClosers[persona_name] and Character.PersonaClosers[persona_name][category]
    if closers and #closers > 0 and math.random() < 0.5 then
        local closer = pick(closers)
        if closer then
            line = line .. ' ' .. fill(closer)
        end
    end
    if #line > 90 then
        return fill(middle)
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
    -- Delayed engage line: say it 5 seconds after engaging, once
    -- Requiem VII has landed, instead of in the Elegy -> Requiem
    -- VII window where a chat line landing there flickered the TP
    -- gear on. (tic runs once per second on the 'time change'
    -- event, so the line lands 5-6s after engage.)
    if self.engage_line_pending and self.fight_start and os.time() - self.fight_start >= 5 then
        self.engage_line_pending = false
        self:say('engage', 'character_engage')
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
            -- Do NOT say the engage line now: it would land in the
            -- Elegy -> Requiem VII window and the TP gear flickered
            -- on whenever a chat line landed there. tic() says it
            -- 5s later, once Requiem VII has landed. (Same reason
            -- the engage emote was removed: anything that fires
            -- in this window delays the follow-up debuff song.)
            self.engage_line_pending = true
        elseif new_status == 'Idle' and old_status == 'Engaged' then
            self.fight_start = nil
            self.engage_line_pending = false
            self.idle_since = os.time()
            self.longidle_said = false
            self:say('idle', 'character_idle')
            self:emote('idle', 0.3)
        elseif new_status == 'Dead' and old_status ~= 'Dead' then
            self.engage_line_pending = false
            self:say('ko', 'character_ko')
        end
    end), player:on_status_change())

    self.dispose_bag:add(player:on_target_change():addAction(function(_, new_target_index, old_target_index)
        if new_target_index and new_target_index ~= old_target_index then
            -- Remember what we are fighting: the kill line fires
            -- when the target clears (the mob died), so by then
            -- there is no target to read the name from.
            if windower and windower.ffxi and windower.ffxi.get_mob_by_target then
                local ok, mob = pcall(windower.ffxi.get_mob_by_target, 't')
                if ok and mob and mob.name then
                    self.last_target_name = mob.name
                end
            end
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
