function TargetBar() : Widget() constructor
{
	drawX = 219;
	drawY = 16;

	width = 202;
	height = 34;

	images =
	[
		spr_gui_bar_enemy_fill,
		spr_gui_bar_enemy,
		spr_gui_bar_blue,
		spr_gui_bar_green
	];

	isActive = false;

	targetName = "";
	fillTarget = 1.0;
	fillDraw = 1.0;
	lerpRate = 0.22;

	fillPadLeft = 20;
	fillMaxW = 177;

	modeSprite = images[1];

	onInit = function()
	{
		setSize(width, height);

		addSubscription("CHANGE HOVER", method(self, onHoverChange));
		addSubscription("HOVERED HP CHANGE", method(self, onHoveredHpChange));
		addSubscription("TOGGLE INVENTORY", method(self, onInventoryToggle));
	};

	onUpdate = function()
	{
		if(!isActive)
		{
			return;
		}

		var prevFill = fillDraw;
		fillDraw = lerp(fillDraw, fillTarget, lerpRate);

		if(abs(fillDraw - prevFill) > 0.001)
		{
			markDirty();
		}
	};

	onHoverChange = function(payload)
	{
		if(is_undefined(payload) || !is_struct(payload))
		{
			isActive = false;
			markDirty();
			return;
		}

		isActive = true;

		if(variable_struct_exists(payload, "name")) targetName = string(payload.name);
		else targetName = "";

		if(variable_struct_exists(payload, "mode"))
		{
			var mode = string(payload.mode);

			if(mode == "blue") modeSprite = images[2];
			else if(mode == "green") modeSprite = images[3];
			else modeSprite = images[1];
		}
		else
		{
			modeSprite = images[1];
		}

		markDirty();
	};

	onHoveredHpChange = function(payload)
	{
		if(is_undefined(payload) || !is_struct(payload))
		{
			return;
		}

		var curHp = 0;
		var maxHp = 0;

		if(variable_struct_exists(payload, "currentHp")) curHp = payload.currentHp;
		else if(variable_struct_exists(payload, "hp")) curHp = payload.hp;

		if(variable_struct_exists(payload, "maxHp")) maxHp = payload.maxHp;
		else if(variable_struct_exists(payload, "hpMax")) maxHp = payload.hpMax;
		else if(variable_struct_exists(payload, "hp_max")) maxHp = payload.hp_max;

		if(maxHp <= 0)
		{
			fillTarget = 0;
			markDirty();
			return;
		}

		fillTarget = clamp(curHp / maxHp, 0, 1);
		markDirty();
	};

	onInventoryToggle = function(payload)
	{
		if(is_undefined(payload) || !is_struct(payload))
		{
			return;
		}

		if(!variable_struct_exists(payload, "open"))
		{
			return;
		}

		var openInv = payload.open;
		drawX = openInv ? 368 : 219;

		markDirty();
	};

	onRender = function()
	{
		if(!isActive)
		{
			return;
		}

		draw_sprite(modeSprite, 0, 0, 0);

		var fillW = round(fillMaxW * fillDraw);

		if(fillW > 0)
		{
			draw_sprite_part(images[0], 0, 0, 0, fillW, height, fillPadLeft, 0);
		}

		draw_sprite(images[1], 0, 0, 0);

		if(targetName != "")
		{
			draw_set_halign(fa_left);
			draw_set_valign(fa_middle);
			draw_text(6, height * 0.5, targetName);
			draw_set_valign(fa_top);
		}
	};
}
