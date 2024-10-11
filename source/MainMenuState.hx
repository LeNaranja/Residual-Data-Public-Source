package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxTimer;


using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.2'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxText>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'credits',
		'options'
	];

	var texto:Array<String> = [
		'Story Mode',
		'Freeplay',
		'Credits',
		'Options'
	];

	public static var firstStart:Bool = true;

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	//Residual Data BG Sprites
	var bgtext:FlxSprite;
	var vignette:FlxSprite;
	var bganim:FlxBackdrop;
	var logoBl:FlxSprite;

	var debugKeys:Array<FlxKey>;

	override function create()
	{
		if (!ClientPrefs.storycomplete)
		{
			optionShit.remove('freeplay');
			texto.remove('Freeplay');
		}
		else
		{
			ClientPrefs.storycomplete = true;
			ClientPrefs.saveSettings();			
		}

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		bganim = new FlxBackdrop(Paths.image('scrolling_BG'));
		bganim.velocity.set(-40, -40);
		bganim.antialiasing = ClientPrefs.globalAntialiasing;
		add(bganim);

		//persistentUpdate = persistentDraw = true;

		bgtext = new FlxSprite(-260, 0).loadGraphic(Paths.image('bg_base_ddlc'));
		bgtext.antialiasing = ClientPrefs.globalAntialiasing;
		add(bgtext);

		logoBl = new FlxSprite(-100, -5);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = ClientPrefs.globalAntialiasing;
		logoBl.scale.set(0.6, 0.6);
		logoBl.animation.addByPrefix('bump', 'Logo anim', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		add(logoBl);
		if (firstStart)
			FlxTween.tween(logoBl, {x: 90}, 1.2, {
				ease: FlxEase.elasticOut,
				onComplete: function(flxTween:FlxTween)
				{
					firstStart = false;
					changeItem();
				}
			});
		else
			logoBl.x = 90;

		if (firstStart)
			FlxTween.tween(bgtext, {x: -60}, 1.2, {
				ease: FlxEase.elasticOut,
				onComplete: function(flxTween:FlxTween)
				{
					firstStart = false;
					changeItem();
				}
			});
		else
			bgtext.x = -60;

		menuItems = new FlxTypedGroup<FlxText>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxText = new FlxText(-350, 370 + (i * 50), 0, texto[i]);
			menuItem.setFormat(Paths.font('riffic.ttf'), 27, FlxColor.WHITE, LEFT);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			menuItem.setBorderStyle(OUTLINE, 0xFF444444, 2);
			menuItem.ID = i;
			menuItems.add(menuItem);

			if (firstStart)
				FlxTween.tween(menuItem, {x: 50}, 1.2 + (i * 0.2), {
					ease: FlxEase.elasticOut,
					onComplete: function(flxTween:FlxTween)
					{
						firstStart = false;
						changeItem();
					}
				});
			else
				menuItem.x = 50;
		}

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin': Residual Data v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		vignette = new FlxSprite(0, 0).loadGraphic(Paths.image('vignette_menu'));
		vignette.alpha = 0.6;
		add(vignette);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.keys.justPressed.F)
			FlxG.fullscreen = !FlxG.fullscreen;

		if (!selectedSomethin)
		{
			//DEV, QUITAR EN LA BUILD DEL PUBLICO
			if (FlxG.keys.justPressed.O)
			{
				trace('unlock all');
				ClientPrefs.storycomplete = true;
				ClientPrefs.saveSettings();
			}
	
			if (FlxG.keys.justPressed.P)
			{
				trace('lock all');
				ClientPrefs.storycomplete = false;
				ClientPrefs.saveSettings();
			}

			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					menuItems.forEach(function(txt:FlxText)
					{
						if (curSelected != txt.ID)
						{
							FlxTween.tween(txt, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									txt.kill();
								}
							});
						}
						else
						{
							if (FlxG.save.data.flashing)
							{
								FlxFlicker.flicker(txt, 1, 0.06, false, false, function(flick:FlxFlicker)
								{
									opciones();
								});								
							}
							else
							{
								new FlxTimer().start(1, function(tmr:FlxTimer)
								{
									opciones();
								});
							}
						}
					});				
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

	//	if (FlxG.sound.music != null)
	//		Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);

	}

	function opciones()
		{
			var daChoice:String = optionShit[curSelected];
	
			switch (daChoice)
			{
				case 'story_mode' | 'story mode':
					PlayState.storyPlaylist = ['RESIDUAL DATA'];
					PlayState.isStoryMode = true;
					PlayState.storyDifficulty = 0;
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + '-hard', PlayState.storyPlaylist[0].toLowerCase());
					PlayState.campaignScore = 0;
					PlayState.campaignMisses = 0;
					LoadingState.loadAndSwitchState(new PlayState(), true);
					FreeplayState.destroyFreeplayVocals();
				case 'freeplay':
					MusicBeatState.switchState(new FreeplayState());
				#if MODS_ALLOWED
				case 'mods':
					MusicBeatState.switchState(new ModsMenuState());
				#end
				case 'awards':
					MusicBeatState.switchState(new AchievementsMenuState());
				case 'credits':
					MusicBeatState.switchState(new CreditsState());
				case 'options':
					LoadingState.loadAndSwitchState(new options.OptionsState());
			}
		}	

	function changeItem(huh:Int = 0)
		{
			curSelected += huh;
	
			if (curSelected >= optionShit.length)
				curSelected = 0;
			if (curSelected < 0)
				curSelected = optionShit.length - 1;
	
			menuItems.forEach(function(txt:FlxText)
			{
				txt.setBorderStyle(OUTLINE, 0xFF444444, 2);
	
				if (txt.ID == curSelected)
					txt.setBorderStyle(OUTLINE, 0xFFFF0513, 2);
	
				txt.updateHitbox();
			});
		}
	override function beatHit()
		{
			super.beatHit();
		
			logoBl.animation.play('bump', true);
		}
}
