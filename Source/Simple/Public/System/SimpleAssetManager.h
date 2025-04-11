// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/AssetManager.h"
#include "SimpleAssetManager.generated.h"

class USimplePawnData;

UCLASS(Config = Game)
class SIMPLE_API USimpleAssetManager : public UAssetManager
{
	GENERATED_BODY()
	
public:
	USimpleAssetManager();

	template<typename AssetType>
	static AssetType* GetAsset(const TSoftObjectPtr<AssetType>& AssetPointer);

	static USimpleAssetManager& Get();
	static UObject* SynchronousLoadAsset(const FSoftObjectPath& AssetPath);

	const USimplePawnData* GetDefaultPawnData() const;

protected:
	UPROPERTY(Config)
	TSoftObjectPtr<USimplePawnData> DefaultPawnData;
};


template<typename AssetType>
AssetType* USimpleAssetManager::GetAsset(const TSoftObjectPtr<AssetType>& AssetPointer)
{
	AssetType* LoadedAsset = nullptr;

	const FSoftObjectPath& AssetPath = AssetPointer.ToSoftObjectPath();

	if (AssetPath.IsValid())
	{
		LoadedAsset = AssetPointer.Get();
		if (!LoadedAsset)
		{
			LoadedAsset = Cast<AssetType>(SynchronousLoadAsset(AssetPath));
			ensureAlwaysMsgf(LoadedAsset, TEXT("Failed to load asset [%s]"), *AssetPointer.ToString());
		}
	}

	return LoadedAsset;
}