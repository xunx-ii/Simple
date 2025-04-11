// Fill out your copyright notice in the Description page of Project Settings.

#include "System/SimpleAssetManager.h"
#include "System/SimplePawnData.h"

USimpleAssetManager::USimpleAssetManager()
{
	DefaultPawnData = nullptr;
}

USimpleAssetManager& USimpleAssetManager::Get()
{
	check(GEngine);

	if (USimpleAssetManager* Singleton = Cast<USimpleAssetManager>(GEngine->AssetManager))
	{
		return *Singleton;
	}

	UE_LOG(LogClass, Fatal, TEXT("Invalid AssetManagerClassName in DefaultEngine.ini.  It must be set to LyraAssetManager!"));

	return *NewObject<USimpleAssetManager>();
}

UObject* USimpleAssetManager::SynchronousLoadAsset(const FSoftObjectPath& AssetPath)
{
	if (AssetPath.IsValid())
	{
		TUniquePtr<FScopeLogTime> LogTimePtr;

		if (UAssetManager::IsInitialized())
		{
			return UAssetManager::GetStreamableManager().LoadSynchronous(AssetPath, false);
		}

		return AssetPath.TryLoad();
	}

	return nullptr;
}

const USimplePawnData* USimpleAssetManager::GetDefaultPawnData() const
{
	return GetAsset(DefaultPawnData);
}
