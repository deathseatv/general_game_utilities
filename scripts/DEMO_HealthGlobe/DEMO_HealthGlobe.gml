function HealthGlobe() : Widget() constructor
{
	drawX = -16;
	drawY = 239;

	width = 128;
	height = 128;

	images =
	[
		spr_heart_missing,
		spr_heart_lower,
		spr_heart_blood,
		spr_heart_outline
	];

	showNumbers = true;

	fillTarget = 1.0;
	fillDraw = 1.0;
	lerpRate = 0.18;

	lastRenderFill = -1.0;
	text = "";

	onInit = function()
	{
		setSize(width, height);
		addSubscription("PLAYER DAMAGE", method(self, onPlayerDamage));
		addSubscription("PLAYER HP CHANGE", method(self, onPlayerDamage));
	};

	onUpdate = function()
	{
		var prevFill = fillDraw;
		fillDraw = lerp(fillDraw, fillTarget, lerpRate);

		if(abs(fillDraw - prevFill) > 0.001)
		{
			markDirty();
		}
	};

	onPlayerDamage = function(payload)
	{
		if(is_undefined(payload) || !is_struct(payload))
		{
			return;
		}

		var curHp = 0;
		var maxHp = 0;

		if(variable_struct_exists(payload, "currentHp")) curHp = payload.currentHp;
		else if(variable_struct_exists(payload, "currentHP")) curHp = payload.currentHP;

		if(variable_struct_exists(payload, "maxHp")) maxHp = payload.maxHp;
		else if(variable_struct_exists(payload, "maxHP")) maxHp = payload.maxHP;

		if(maxHp <= 0)
		{
			fillTarget = 0;
			text = "";
			markDirty();
			return;
		}

		fillTarget = clamp(curHp / maxHp, 0, 1);
		text = string(curHp) + " / " + string(maxHp);

		markDirty();
	};

	onRender = function()
	{
		var spriteW = width;
		var spriteH = height;

		draw_sprite(images[0], 0, 0, 0);

		var fillH = round(spriteH * fillDraw);

		if(fillH > 0)
		{
			var srcTop = spriteH - fillH;
			draw_sprite_part(images[2], 0, 0, srcTop, spriteW, fillH, 0, srcTop);
		}

		draw_sprite(images[3], 0, 0, 0);

		if(showNumbers && text != "")
		{
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_text(spriteW * 0.5, spriteH * 0.55, text);
			draw_set_halign(fa_left);
			draw_set_valign(fa_top);
		}
	};
}
