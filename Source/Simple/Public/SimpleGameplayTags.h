// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "NativeGameplayTags.h"

namespace SimpleGameplayTags
{
	SIMPLE_API	UE_DECLARE_GAMEPLAY_TAG_EXTERN(InputTag_Move);
	SIMPLE_API	UE_DECLARE_GAMEPLAY_TAG_EXTERN(InputTag_Look_Mouse);

	SIMPLE_API FGameplayTag FindTagByString(const FString& TagString, bool bMatchPartialString = false);
};
