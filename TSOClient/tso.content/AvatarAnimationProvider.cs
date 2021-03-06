﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using tso.vitaboy;
using tso.content.framework;
using System.Text.RegularExpressions;
using tso.content.codecs;

namespace tso.content
{
    /// <summary>
    /// Provides access to animation (*.anim) data in FAR3 archives.
    /// </summary>
    public class AvatarAnimationProvider : FAR3Provider<Animation>
    {
        public AvatarAnimationProvider(Content contentManager)
            : base(contentManager, new AnimationCodec(), new Regex(".*\\\\animations\\\\.*\\.dat"))
        {
        }
    }
}
