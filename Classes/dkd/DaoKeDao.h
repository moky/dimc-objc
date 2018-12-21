//
//  DaoKeDao.h
//  DaoKeDao
//
//  Created by Albert Moky on 2018/10/1.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for DaoKeDao.
FOUNDATION_EXPORT double DaoKeDaoVersionNumber;

//! Project version string for DaoKeDao.
FOUNDATION_EXPORT const unsigned char DaoKeDaoVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DaoKeDao/PublicHeader.h>

// MKM
//#import <MingKeMing/MingKeMing.h>

#if !defined(__DAO_KE_DAO__)
#define __DAO_KE_DAO__ 1

// Extends
#import "MKMAccount+Message.h"
#import "MKMUser+Message.h"
#import "MKMGroup+Message.h"

// Types
//#import "DKDDictionary.h"

// Message
#import "DKDEnvelope.h"
#import "DKDMessage.h"
#import "DKDInstantMessage.h"
#import "DKDSecureMessage.h"
#import "DKDReliableMessage.h"

// Content
#import "DKDMessageContent.h"
#import "DKDMessageContent+Text.h"
#import "DKDMessageContent+File.h"
#import "DKDMessageContent+Image.h"
#import "DKDMessageContent+Audio.h"
#import "DKDMessageContent+Video.h"
#import "DKDMessageContent+Webpage.h"
#import "DKDMessageContent+Quote.h"
#import "DKDMessageContent+Command.h"
#import "DKDMessageContent+Forward.h"

//-
#import "DKDTransceiver.h"
#import "DKDKeyStore.h"

#endif /* ! __DAO_KE_DAO__ */