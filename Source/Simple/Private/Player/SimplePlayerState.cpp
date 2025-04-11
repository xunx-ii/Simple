// Fill out your copyright notice in the Description page of Project Settings.

#include "Player/SimplePlayerState.h"
#include "System/SimpleExperienceDefinition.h"
#include "Online/SimpleGameState.h"
#include "Online/SimpleGameMode.h"
#include "Net/UnrealNetwork.h"
#include "System/SimplePawnData.h"
#include "System/SimpleAbilitySet.h"
#include "Engine/World.h"
#include "Abilities/SimpleAbilitySystemComponent.h"


ASimplePlayerState::ASimplePlayerState()
{
	AbilitySystemComponent = CreateDefaultSubobject<USimpleAbilitySystemComponent>(TEXT("AbilitySystemComponent"));
	AbilitySystemComponent->SetIsReplicated(true);
	AbilitySystemComponent->SetReplicationMode(EGameplayEffectReplicationMode::Mixed);

	SetNetUpdateFrequency(100.0f);

	bPawnDataIsLoaded = false;
}

void ASimplePlayerState::PostInitializeComponents()
{
	Super::PostInitializeComponents();

	if (AbilitySystemComponent)
	{
		AbilitySystemComponent->InitAbilityActorInfo(this, GetPawn());
	}
	
	UWorld* World = GetWorld();
	if (World && World->IsGameWorld() && World->GetNetMode() != NM_Client)
	{
		ASimpleGameState* SimpleGameState = Cast<ASimpleGameState>(GetWorld()->GetGameState());
		if (SimpleGameState)
		{
			SimpleGameState->CallOrRegister_OnExperienceLoaded(FOnSimpleExperienceLoaded::FDelegate::CreateUObject(this, &ThisClass::OnExperienceLoaded));
		}
	}
}

void ASimplePlayerState::SetPawnData(const USimplePawnData* PawnData)
{

	if (GetLocalRole() != ROLE_Authority)
	{
		return;
	}

	if (GamePawnData)
	{
		UE_LOG(LogClass, Error, TEXT("Trying to set PawnData [%s] on player state [%s] that already has valid PawnData [%s]."), *GetNameSafe(PawnData), *GetNameSafe(this), *GetNameSafe(GamePawnData));
		return;
	}

	MARK_PROPERTY_DIRTY_FROM_NAME(ThisClass, GamePawnData, this);
	GamePawnData = PawnData;

	for (const USimpleAbilitySet* AbilitySet : GamePawnData->AbilitySets)
	{
		if (AbilitySet)
		{
			AbilitySet->GiveToAbilitySystem(AbilitySystemComponent, nullptr);
		}
	}

	bPawnDataIsLoaded = true;

	OnPawnDataLoaded.Broadcast(GamePawnData);
	OnPawnDataLoaded.Clear();

	ForceNetUpdate();
}

UAbilitySystemComponent* ASimplePlayerState::GetAbilitySystemComponent() const
{
	return GetSimpleAbilitySystemComponent();
}


void ASimplePlayerState::CallOrRegister_OnPawnDataLoaded(FOnSimplePawnDataLoaded::FDelegate&& Delegate)
{
	if (bPawnDataIsLoaded)
	{
		Delegate.Execute(GamePawnData);
	}
	else
	{
		OnPawnDataLoaded.Add(MoveTemp(Delegate));
	}
}

void ASimplePlayerState::OnExperienceLoaded(const USimpleExperienceDefinition* CurrentExperience)
{
	if (ASimpleGameMode* SimpleGameMode = GetWorld()->GetAuthGameMode<ASimpleGameMode>())
	{
		if (const USimplePawnData* NewPawnData = SimpleGameMode->GetPawnDataForController(GetOwningController()))
		{
			SetPawnData(NewPawnData);
		}
		else
		{
			UE_LOG(LogClass, Error, TEXT("ASimplePlayerState::OnExperienceLoaded(): Unable to find PawnData to initialize player state [%s]!"), *GetNameSafe(this));
		}
	}
}

void ASimplePlayerState::OnRep_GamePawnData()
{
	bPawnDataIsLoaded = true;
}

void ASimplePlayerState::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);

	FDoRepLifetimeParams SharedParams;
	SharedParams.bIsPushBased = true;

	DOREPLIFETIME_WITH_PARAMS_FAST(ThisClass, GamePawnData, SharedParams);
}