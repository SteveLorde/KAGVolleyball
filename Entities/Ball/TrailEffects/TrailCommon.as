// TrailCommon.as
// Created by [KFC]Chrispin // edited version by Monkey_Feats

// Feel free to use or modify this however you'd like for your own mods. You're welcome ;)
// Adding trail physics, gravity, oscillation, and random trail noise are a few ideas that wouldn't be too difficult to add.

Random _r_trail();

class TrailEffect
{
	f32 startWidth;
    f32 endWidth;
	f32 timePerNewSeg;
	f32 segCreationTimer;
	f32 decayTime;

    f32 minSegDist; // minimun distance between segments before new one created

    f32 smoothingFactor;

    f32 Z;

    u8 baseAlpha;
	SColor color;

	TrailSegment@[] segments;	// ordered by oldest segment first, newest last

    string texName;
    CFileImage@ texImage;
    Vec2f texDim;
    bool leaveTexBehind;

    f32 fadeInDist;
    f32 fadeOutDist;

    f32 texScrollSpeed;

    Vec2f emitPos;
    u16 emitterBlobID;
    Vec2f emitOffset;

    TrailEffect()
    {
		startWidth = 16.0f;
        endWidth = 0.0f;
		timePerNewSeg = 1.0f;
		segCreationTimer = 0;
		decayTime = 10.0f;

        minSegDist = 4.0f;

        smoothingFactor = 0.1f;

        Z = 1.0f;

        baseAlpha = 255;
        color = SColor(baseAlpha,255,255,255);

        texName = "trail_test.png";
        @texImage = CFileImage(texName);
        if(texImage.isLoaded())
        {
            texDim.x = texImage.getWidth();
            texDim.y = texImage.getHeight();
        }
        leaveTexBehind = true;

        fadeInDist = 24.0f;
        fadeOutDist = 64.0f;

        texScrollSpeed = 0.0f;

        emitOffset = Vec2f_zero;
    }

    void setTexture(string _texName)
    {
        texName = _texName;
        @texImage = CFileImage(texName);
        if(texImage.isLoaded())
        {
            texDim.x = texImage.getWidth();
            texDim.y = texImage.getHeight();
        }
    }

    void setBaseAlpha(u8 alpha)
    {
        baseAlpha = alpha;
        color.setAlpha(baseAlpha);
    }

    void Update(Vertex[] &inout v_raw)
    {
        f32 deltaT = getRenderDeltaTime();

        u32 numSegs = segments.length();

        CBlob@ blob = getBlobByNetworkID(emitterBlobID);
        if (blob !is null)
        {
            emitPos = blob.getInterpolatedPosition() + emitOffset;
        }

        bool emitterPosAtZero = emitPos == Vec2f_zero; // This boolean used to check if emitter blob is properly initialized and inside the map
        emitPos += emitOffset;

        // create new trail segments when needed
        if (segCreationTimer > 0)
        {
            segCreationTimer -= deltaT;
        }
        else if (!emitterPosAtZero)
        {   
            bool createNewSeg = false;
            if (numSegs <= 1)
            {
                createNewSeg = true;
            }
            else
            {
                TrailSegment@ firstSeg = segments[0];    // head segment
                TrailSegment@ secSeg = segments[1];     // segment after head   
                            
                // check if we've reached the minimum distance between segments
                if ((firstSeg.pos - secSeg.pos).getLength() >= minSegDist)
                {
                    createNewSeg = true;
                }
            }

            if (createNewSeg)
            {
                TrailSegment@ newSeg = TrailSegment(emitPos, startWidth, decayTime);
                segments.insert(0,newSeg);
                numSegs = segments.length();
                segCreationTimer = timePerNewSeg;
            }
        }

        if (numSegs > 0)
        {
            TrailSegment@ firstSeg = segments[0];           // head segment
            TrailSegment@ lastSeg = segments[numSegs - 1];  // tail segment

            // randomize texture offset when segments are no longer being drawn
            if (numSegs == 2)
            {
                TrailSegment@ secSeg = segments[1];     // segment after head
                if (firstSeg.texEndLen == secSeg.texEndLen)
                {
                    firstSeg.texEndLen = _r_trail.NextFloat();
                }
            }

            // remove tail segment if fully decayed
            if (lastSeg.lifetime <= 0.0f)
            {
                segments.removeAt(numSegs - 1);
                numSegs = segments.length();
            }
        }

        if (numSegs > 1)
        {
            TrailSegment@ firstSeg = segments[0];            // head segment
            TrailSegment@ secSeg = segments[1];             // segment after head
            TrailSegment@ lastSeg = segments[numSegs-1];    // tail segment
            TrailSegment@ penSeg = segments[numSegs-2];     // segment before tail

            // make leading head segment follow current pos
            if (!emitterPosAtZero)
            {
                firstSeg.pos = emitPos;
                firstSeg.angle = (emitPos - secSeg.pos).getAngle();
            }

            // set starting angle of segment after the head
            if (numSegs == 2)
            {
                secSeg.angle = firstSeg.angle;
            }

            // make end tail segment move toward the penultimate as it decays
            Vec2f moveNorm = penSeg.pos - lastSeg.pos;
            f32 moveDist = moveNorm.Normalize();
            f32 moveSpeed = moveDist/lastSeg.lifetime;
            lastSeg.pos += moveNorm*(Maths::Min(moveSpeed*deltaT, moveDist));

            f32 moveAngle = penSeg.angle - lastSeg.angle;
            if (moveAngle > 180.0f)
                moveAngle -= 360.0f;
            else if (moveAngle < -180.0f)
                moveAngle += 360.0f;
            f32 rotSpeed = moveAngle/lastSeg.lifetime;
            lastSeg.angle += rotSpeed*deltaT;

            // handle tail segment texture offset seperately due to its constant movement
            if (leaveTexBehind)
            {
                f32 quadLength = (lastSeg.pos - penSeg.pos).getLength();
                f32 texStartX = -(1.0f - (penSeg.texEndLen % 1.0f));
                f32 texScaleX = quadLength/(texDim.x*1.0f);
                lastSeg.texEndLen = texStartX - texScaleX;
            }
        }

        // go through all segments
        for(u32 i = 0; i < numSegs; i++)
        {
            TrailSegment@ iSeg = segments[i];

            // setup rendering of trail segments
            if (numSegs > 1 && i < numSegs - 1)    // check if there is another segment to complete the quad
            {
                //test
                TrailSegment@ nextSeg = segments[i+1];

                // handle lead segment texture separately from the rest
                f32 quadLength = (nextSeg.pos - iSeg.pos).getLength();
                f32 texScaleX = quadLength/(texDim.x*1.0f);
                if (i == 0 && leaveTexBehind) 
                {
                    iSeg.texEndLen = nextSeg.texEndLen - texScaleX;
                }

                // adjust texture scale and start coords based on length and previous segments
                f32 texStartX = -(1.0f - (iSeg.texEndLen % 1.0f));
                nextSeg.texEndLen = texStartX + texScaleX;

                // calculate each segment's alpha value once per tick
                if (i == 0)
                {
                    // trail alpha fade in
                    if (fadeInDist > 0)
                    {
                        for(u32 j = 0; j < numSegs; j++)
                        {
                            TrailSegment@ jSeg = segments[j];
                            if (j == 0)
                            {
                                jSeg.alpha = 0;
                            }
                            else
                            {
                                TrailSegment@ jPrevSeg = segments[j-1];

                                // go ahead and reset the alpha of all segments down the line
                                if (jPrevSeg.alpha >= 255)
                                {
                                    jSeg.alpha = 255;
                                }
                                else
                                {
                                    f32 jPrevQuadLength = (jSeg.pos - jPrevSeg.pos).getLength();
                                    jSeg.alpha = Maths::Min(jPrevSeg.alpha + (jPrevQuadLength/fadeInDist)*255.0f, 255);
                                }
                            }
                        }
                    }

                    // trail alpha fade out
                    if (fadeOutDist > 0)
                    {
                        for(u32 j = numSegs-1; j > 0; j--)    // start from the end of the trail to the beginning
                        {
                            TrailSegment@ jSeg = segments[j];
                            if (j == numSegs-1)
                            {
                                jSeg.alpha = 0;
                            }
                            else
                            {
                                TrailSegment@ jNextSeg = segments[j+1];
                                f32 jNextQuadLength = (jSeg.pos - jNextSeg.pos).getLength();
                                u8 jSegAlpha = Maths::Min(jNextSeg.alpha + (jNextQuadLength/fadeOutDist)*255.0f, 255);

                                // give j seg the minimum alpha if overlapping with the faded-in segments
                                if (jSeg.alpha < 255)   
                                {
                                    jSegAlpha = Maths::Min(jSegAlpha,jSeg.alpha);
                                }

                                jSeg.alpha = jSegAlpha;

                                // we can stop iterating through the trail since alpha is maxxed
                                if (jSeg.alpha >= 255)  
                                    break;
                            }
                        }
                    }
                }


                // add quad verticies between each segment to render queue 
                AddQuadBetweenSegments(iSeg, nextSeg, texStartX, texScaleX, v_raw);
            }   

            // update segment values
            iSeg.width += (endWidth - startWidth)*(deltaT/decayTime);
            iSeg.lifetime -= deltaT;

            // smoothing
            if (smoothingFactor > 0)
            {
                if (i > 0 && i < numSegs - 1)  // ommit pos smoothing on first 2 and last 2 segments
                {
                    TrailSegment@ prevSeg = segments[i-1];
                    TrailSegment@ nextSeg = segments[i+1];

                    Vec2f midPos = (prevSeg.pos + nextSeg.pos)*0.5f;    // get average pos
                    Vec2f moveVec = midPos - iSeg.pos;
                    iSeg.pos += moveVec*smoothingFactor;
                }

                // update angles to face toward next leading segment as pos changes are made
                if (i < numSegs - 1)
                {
                    TrailSegment@ nextSeg = segments[i+1];
                    iSeg.angle = (iSeg.pos - nextSeg.pos).getAngle();
                }
            }     
        }        
    }

    void AddQuadBetweenSegments(TrailSegment@ seg1, TrailSegment@ seg2, f32 texStartX, f32 texScaleX, Vertex[] &inout v_raw)
    {
      	Vec2f topVert1 = seg1.pos + Vec2f(0,-1).RotateByDegrees(-seg1.angle)*seg1.width*0.5f;
    	Vec2f botVert1 = seg1.pos + Vec2f(0,1).RotateByDegrees(-seg1.angle)*seg1.width*0.5f;    	
    	Vec2f topVert2 = seg2.pos + Vec2f(0,-1).RotateByDegrees(-seg2.angle)*seg2.width*0.5f;
    	Vec2f botVert2 = seg2.pos + Vec2f(0,1).RotateByDegrees(-seg2.angle)*seg2.width*0.5f;

        SColor seg1Color = color;
        seg1Color.setAlpha(Maths::Min(seg1.alpha, baseAlpha));
        SColor seg2Color = color;
        seg2Color.setAlpha(Maths::Min(seg2.alpha, baseAlpha));
		
		v_raw.push_back(Vertex(topVert2.x, topVert2.y, Z, texStartX + texScaleX, 0, seg2Color)); //top right
		v_raw.push_back(Vertex(topVert1.x, topVert1.y, Z, texStartX, 0, seg1Color)); //top left
		v_raw.push_back(Vertex(botVert1.x, botVert1.y, Z, texStartX, 1, seg1Color)); //bot left
		v_raw.push_back(Vertex(botVert2.x, botVert2.y, Z, texStartX + texScaleX, 1, seg2Color)); //bot right
    }
}

class TrailSegment
{
	Vec2f pos;
    f32 angle;
    f32 width;
    f32 lifetime;

    u8 alpha;

    f32 texEndLen;  // texture end length in units of texture widths

    TrailSegment(Vec2f _pos, f32 _width, f32 _lifetime)
    {
        pos = _pos;
        angle = 0;
        width = _width;
        lifetime = _lifetime;

        alpha = 255;

        texEndLen = 1.0f;
    }
}
