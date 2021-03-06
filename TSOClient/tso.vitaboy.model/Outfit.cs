﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using tso.common.utils;
using tso.common.content;
using tso.files.utils;

namespace tso.vitaboy
{
    public class Outfit {

        public uint LightAppearanceFileID;
        public uint LightAppearanceTypeID;

        public uint MediumAppearanceFileID;
        public uint MediumAppearanceTypeID;

        public uint DarkAppearanceFileID;
        public uint DarkAppearanceTypeID;

        public uint HandGroup;
        public uint Region;

        public ContentID GetAppearance(AppearanceType type)
        {
            switch (type)
            {
                case AppearanceType.Light:
                    return new ContentID(LightAppearanceTypeID, LightAppearanceFileID);
                case AppearanceType.Medium:
                    return new ContentID(MediumAppearanceTypeID, MediumAppearanceFileID);
                case AppearanceType.Dark:
                    return new ContentID(DarkAppearanceTypeID, DarkAppearanceFileID);
            }
            return null;
        }

        public void Read(Stream stream)
        {
            using (var io = IoBuffer.FromStream(stream))
            {
                var version = io.ReadUInt32();
                var unknown = io.ReadUInt32();

                LightAppearanceFileID = io.ReadUInt32();
                LightAppearanceTypeID = io.ReadUInt32();

                MediumAppearanceFileID = io.ReadUInt32();
                MediumAppearanceTypeID = io.ReadUInt32();

                DarkAppearanceFileID = io.ReadUInt32();
                DarkAppearanceTypeID = io.ReadUInt32();

                HandGroup = io.ReadUInt32();
                Region = io.ReadUInt32();
            }
        }

    }
}
