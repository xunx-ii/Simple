// Fill out your copyright notice in the Description page of Project Settings.


#include "Online/SimpleGameState.h"
#include "Net/UnrealNetwork.h"
#include "System/SimpleAssetManager.h"
#include "System/SimpleExperienceDefinition.h"

ASimpleGameState::ASimpleGameState()
{
	CurrentExperience = nullptr;
	bIsExperienceLoaded = false;
}

bool ASimpleGameState::IsExperienceLoaded() const
{
	return (bIsExperienceLoaded == true) && (CurrentExperience != nullptr);
}

void ASimpleGameState::SetCurrentExperience(FPrimaryAssetId ExperienceId)
{
	USimpleAssetManager& AssetManager = USimpleAssetManager::Get();
	FSoftObjectPath AssetPath = AssetManager.GetPrimaryAssetPath(ExperienceId);
	TSubclassOf<USimpleExperienceDefinition> AssetClass = Cast<UClass>(AssetPath.TryLoad());
	check(AssetClass);
	const USimpleExperienceDefinition* Experience = GetDefault<USimpleExperienceDefinition>(AssetClass);

	check(Experience != nullptr);
	check(CurrentExperience == nullptr);
	CurrentExperience = Experience;
	StartExperienceLoad();
}

const USimpleExperienceDefinition* ASimpleGameState::GetCurrentExperience() const
{
	return CurrentExperience;
}

void ASimpleGameState::CallOrRegister_OnExperienceLoaded(FOnSimpleExperienceLoaded::FDelegate&& Delegate)
{
	if (CurrentExperience != nullptr)
	{
		Delegate.Execute(CurrentExperience);
	}
	else
	{
		OnExperienceLoaded.Add(MoveTemp(Delegate));
	}
}

void ASimpleGameState::OnRep_CurrentExperience()
{
	StartExperienceLoad();
}

void ASimpleGameState::StartExperienceLoad()
{
	// 开始加载资源
	LoadingAssetsInTheExperience(CurrentExperience);
}

void ASimpleGameState::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);

	DOREPLIFETIME(ThisClass, CurrentExperience);
}

void ASimpleGameState::LoadingAssetsInTheExperience(const USimpleExperienceDefinition* Experience)
{
	USimpleAssetManager& AssetManager = USimpleAssetManager::Get();

	TSet<FPrimaryAssetId> BundleAssetList;
	TSet<FSoftObjectPath> RawAssetList;

	BundleAssetList.Add(Experience->GetPrimaryAssetId());

	// Load assets associated with the experience
	TArray<FName> BundlesToLoad;
	BundlesToLoad.Add(TEXT("Equipped"));

	const ENetMode OwnerNetMode = GetNetMode();
	const bool bLoadClient = GIsEditor || (OwnerNetMode != NM_DedicatedServer);
	const bool bLoadServer = GIsEditor || (OwnerNetMode != NM_Client);
	if (bLoadClient)
	{
		BundlesToLoad.Add(TEXT("Client"));
	}
	if (bLoadServer)
	{
		BundlesToLoad.Add(TEXT("Server"));
	}

	TSharedPtr<FStreamableHandle> BundleLoadHandle = nullptr;
	if (BundleAssetList.Num() > 0)
	{
		BundleLoadHandle = AssetManager.ChangeBundleStateForPrimaryAssets(BundleAssetList.Array(), BundlesToLoad, {}, false, FStreamableDelegate(), FStreamableManager::AsyncLoadHighPriority);
	}

	TSharedPtr<FStreamableHandle> RawLoadHandle = nullptr;
	if (RawAssetList.Num() > 0)
	{
		RawLoadHandle = AssetManager.LoadAssetList(RawAssetList.Array(), FStreamableDelegate(), FStreamableManager::AsyncLoadHighPriority, TEXT("StartExperienceLoad()"));
	}

	TSharedPtr<FStreamableHandle> Handle = nullptr;
	if (BundleLoadHandle.IsValid() && RawLoadHandle.IsValid())
	{
		Handle = AssetManager.GetStreamableManager().CreateCombinedHandle({ BundleLoadHandle, RawLoadHandle });
	}
	else
	{
		Handle = BundleLoadHandle.IsValid() ? BundleLoadHandle : RawLoadHandle;
	}

	FStreamableDelegate OnAssetsLoadedDelegate = FStreamableDelegate::CreateUObject(this, &ThisClass::OnExperienceLoadComplete);
	if (!Handle.IsValid() || Handle->HasLoadCompleted())
	{
		// Assets were already loaded, call the delegate now
		FStreamableHandle::ExecuteDelegate(OnAssetsLoadedDelegate);
	}
	else
	{
		Handle->BindCompleteDelegate(OnAssetsLoadedDelegate);

		Handle->BindCancelDelegate(FStreamableDelegate::CreateLambda([OnAssetsLoadedDelegate]()
			{
				OnAssetsLoadedDelegate.ExecuteIfBound();
			}));
	}
}

void ASimpleGameState::OnExperienceLoadComplete()
{
	bIsExperienceLoaded = true;

	OnExperienceLoaded.Broadcast(CurrentExperience);
	OnExperienceLoaded.Clear();

	// Apply any necessary scalability settings
}
