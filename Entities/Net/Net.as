
void onInit(CSprite@ this)
{
    CBlob@ blob = this.getBlob();

    blob.Tag("invincible");

    blob.SetFacingLeft(XORRandom(2) == 0);
    blob.getShape().SetStatic( true );

    this.SetZ(500.0f);
    this.RemoveSpriteLayer("otherhalf");
    CSpriteLayer@ half = this.addSpriteLayer("otherhalf", "Net.png" , 8, 40,0,0);

    if (half !is null)
    {
        Animation@ anim = half.addAnimation("default", 0, false);
        anim.AddFrame(1);

        half.SetOffset(Vec2f(-4.0f, 2.0f));
        half.SetRelativeZ(-1200.0f);
        half.SetVisible(true);
    }

    // this.SetEmitSound("templar.ogg");
    // this.SetEmitSoundVolume(0.5f);
    // this.SetEmitSoundPaused(false);
}