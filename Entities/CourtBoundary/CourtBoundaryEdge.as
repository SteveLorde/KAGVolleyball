
void onInit(CSprite@ this)
{
    this.SetZ(-180.0f);
    this.RemoveSpriteLayer("otherhalf");
    CSpriteLayer@ half = this.addSpriteLayer("otherhalf", "CourtBoundary.png" , 48, 8);

    if (half !is null)
    {
        Animation@ anim = half.addAnimation("default", 0, false);
        anim.AddFrame(1);

        half.SetOffset(Vec2f(-2.0f, 5.0f));
        half.SetRelativeZ(1000.0f);
        half.SetVisible(true);
    }
}