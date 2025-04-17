// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/SimpleHealthComponent.h"
#include "Net/UnrealNetwork.h"
#include "SimpleGameplayTags.h"
#include "Abilities/SimpleAbilitySystemComponent.h"
#include "Abilities/AttributeSets/SimpleHealthAttributeSet.h"

USimpleHealthComponent::USimpleHealthComponent()
{
	PrimaryComponentTick.bStartWithTickEnabled = false;
	PrimaryComponentTick.bCanEverTick = false;

	SetIsReplicatedByDefault(true);

	AbilitySystemComponent = nullptr;
	SimpleHealthAttributeSet = nullptr;

	DeathState = ESimpleDeathState::NotDead;
}

float USimpleHealthComponent::GetHealth() const
{
	return (SimpleHealthAttributeSet ? SimpleHealthAttributeSet->GetHealth() : 0.0f);
}

float USimpleHealthComponent::GetMaxHealth() const
{
	return (SimpleHealthAttributeSet ? SimpleHealthAttributeSet->GetMaxHealth() : 0.0f);
}

float USimpleHealthComponent::GetHealthNormalized() const
{
	if (SimpleHealthAttributeSet)
	{
		const float Health = SimpleHealthAttributeSet->GetHealth();
		const float MaxHealth = SimpleHealthAttributeSet->GetMaxHealth();

		return ((MaxHealth > 0.0f) ? (Health / MaxHealth) : 0.0f);
	}

	return 0.0f;
}

void USimpleHealthComponent::OnUnregister()
{
	UninitializeFromAbilitySystem();

	Super::OnUnregister();
}

void USimpleHealthComponent::ClearGameplayTags()
{
	if (AbilitySystemComponent)
	{
		AbilitySystemComponent->SetLooseGameplayTagCount(SimpleGameplayTags::Status_Death_Dying, 0);
		AbilitySystemComponent->SetLooseGameplayTagCount(SimpleGameplayTags::Status_Death_Dead, 0);
	}
}

void USimpleHealthComponent::InitializeWithAbilitySystem(USimpleAbilitySystemComponent* SimpleAbilitySystemComponent)
{
	AActor* Owner = GetOwner();

	if (!Owner)
	{
		return;
	}

	if (AbilitySystemComponent)
	{
		return;
	}

	AbilitySystemComponent = SimpleAbilitySystemComponent;

	if (!AbilitySystemComponent)
	{
		UE_LOG(LogClass, Error, TEXT("USimpleHealthComponent: Cannot initialize health component for owner [%s] with NULL ability system."), *GetNameSafe(Owner));
		return;
	}

	SimpleHealthAttributeSet = AbilitySystemComponent->GetSet<USimpleHealthAttributeSet>();

	if (!SimpleHealthAttributeSet)
	{
		UE_LOG(LogClass, Error, TEXT("USimpleHealthComponent: Cannot initialize health component for owner [%s] with NULL health set on the ability system."), *GetNameSafe(Owner));
		return;
	}

	SimpleHealthAttributeSet->OnHealthChanged.AddUObject(this, &ThisClass::HandleHealthChanged);
	SimpleHealthAttributeSet->OnMaxHealthChanged.AddUObject(this, &ThisClass::HandleMaxHealthChanged);
	SimpleHealthAttributeSet->OnOutOfHealth.AddUObject(this, &ThisClass::HandleOutOfHealth);

	AbilitySystemComponent->SetNumericAttributeBase(USimpleHealthAttributeSet::GetHealthAttribute(), SimpleHealthAttributeSet->GetMaxHealth());

	ClearGameplayTags();

	OnHealthChanged.Broadcast(this, SimpleHealthAttributeSet->GetHealth(), SimpleHealthAttributeSet->GetHealth(), nullptr);
	OnMaxHealthChanged.Broadcast(this, SimpleHealthAttributeSet->GetHealth(), SimpleHealthAttributeSet->GetHealth(), nullptr);
}

void USimpleHealthComponent::UninitializeFromAbilitySystem()
{
	ClearGameplayTags();

	if (SimpleHealthAttributeSet)
	{
		SimpleHealthAttributeSet->OnHealthChanged.RemoveAll(this);
		SimpleHealthAttributeSet->OnMaxHealthChanged.RemoveAll(this);
	}

	SimpleHealthAttributeSet = nullptr;
	AbilitySystemComponent = nullptr;
}

void USimpleHealthComponent::StartDeath()
{
	if (DeathState != ESimpleDeathState::NotDead)
	{
		return;
	}

	DeathState = ESimpleDeathState::DeathStarted;

	if (AbilitySystemComponent)
	{
		AbilitySystemComponent->SetLooseGameplayTagCount(SimpleGameplayTags::Status_Death_Dying, 1);
	}

	AActor* Owner = GetOwner();
	check(Owner);

	OnDeathStarted.Broadcast(Owner);

	Owner->ForceNetUpdate();
}

void USimpleHealthComponent::FinishDeath()
{
	if (DeathState != ESimpleDeathState::DeathStarted)
	{
		return;
	}

	DeathState = ESimpleDeathState::DeathFinished;

	if (AbilitySystemComponent)
	{
		AbilitySystemComponent->SetLooseGameplayTagCount(SimpleGameplayTags::Status_Death_Dead, 1);
	}

	AActor* Owner = GetOwner();
	check(Owner);

	OnDeathFinished.Broadcast(Owner);

	Owner->ForceNetUpdate();
}

void USimpleHealthComponent::OnRep_DeathState(ESimpleDeathState OldDeathState)
{
	const ESimpleDeathState NewDeathState = DeathState;

	// Revert the death state for now since we rely on StartDeath and FinishDeath to change it.
	DeathState = OldDeathState;

	if (OldDeathState > NewDeathState)
	{
		// The server is trying to set us back but we've already predicted past the server state.
		UE_LOG(LogClass, Warning, TEXT("USimpleHealthComponent: Predicted past server death state [%d] -> [%d] for owner [%s]."), (uint8)OldDeathState, (uint8)NewDeathState, *GetNameSafe(GetOwner()));
		return;
	}

	if (OldDeathState == ESimpleDeathState::NotDead)
	{
		if (NewDeathState == ESimpleDeathState::DeathStarted)
		{
			StartDeath();
		}
		else if (NewDeathState == ESimpleDeathState::DeathFinished)
		{
			StartDeath();
			FinishDeath();
		}
		else
		{
			UE_LOG(LogClass, Error, TEXT("USimpleHealthComponent: Invalid death transition [%d] -> [%d] for owner [%s]."), (uint8)OldDeathState, (uint8)NewDeathState, *GetNameSafe(GetOwner()));
		}
	}
	else if (OldDeathState == ESimpleDeathState::DeathStarted)
	{
		if (NewDeathState == ESimpleDeathState::DeathFinished)
		{
			FinishDeath();
		}
		else
		{
			UE_LOG(LogClass, Error, TEXT("USimpleHealthComponent: Invalid death transition [%d] -> [%d] for owner [%s]."), (uint8)OldDeathState, (uint8)NewDeathState, *GetNameSafe(GetOwner()));
		}
	}

	ensureMsgf((DeathState == NewDeathState), TEXT("USimpleHealthComponent: Death transition failed [%d] -> [%d] for owner [%s]."), (uint8)OldDeathState, (uint8)NewDeathState, *GetNameSafe(GetOwner()));
}

void USimpleHealthComponent::HandleHealthChanged(AActor* DamageInstigator, AActor* DamageCauser, const FGameplayEffectSpec* DamageEffectSpec, float DamageMagnitude, float OldValue, float NewValue)
{
	OnHealthChanged.Broadcast(this, OldValue, NewValue, DamageInstigator);
}

void USimpleHealthComponent::HandleMaxHealthChanged(AActor* DamageInstigator, AActor* DamageCauser, const FGameplayEffectSpec* DamageEffectSpec, float DamageMagnitude, float OldValue, float NewValue)
{
	OnMaxHealthChanged.Broadcast(this, OldValue, NewValue, DamageInstigator);
}

void USimpleHealthComponent::HandleOutOfHealth(AActor* DamageInstigator, AActor* DamageCauser, const FGameplayEffectSpec* DamageEffectSpec, float DamageMagnitude, float OldValue, float NewValue)
{
#if WITH_SERVER_CODE
	if (AbilitySystemComponent && DamageEffectSpec)
	{
		/*
		// Send the "GameplayEvent.Death" gameplay event through the owner's ability system.  This can be used to trigger a death gameplay ability.
		{
			FGameplayEventData Payload;
			Payload.EventTag = LyraGameplayTags::GameplayEvent_Death;
			Payload.Instigator = DamageInstigator;
			Payload.Target = AbilitySystemComponent->GetAvatarActor();
			Payload.OptionalObject = DamageEffectSpec->Def;
			Payload.ContextHandle = DamageEffectSpec->GetEffectContext();
			Payload.InstigatorTags = *DamageEffectSpec->CapturedSourceTags.GetAggregatedTags();
			Payload.TargetTags = *DamageEffectSpec->CapturedTargetTags.GetAggregatedTags();
			Payload.EventMagnitude = DamageMagnitude;

			FScopedPredictionWindow NewScopedWindow(AbilitySystemComponent, true);
			AbilitySystemComponent->HandleGameplayEvent(Payload.EventTag, &Payload);
		}

		// Send a standardized verb message that other systems can observe
		{
			FLyraVerbMessage Message;
			Message.Verb = TAG_Lyra_Elimination_Message;
			Message.Instigator = DamageInstigator;
			Message.InstigatorTags = *DamageEffectSpec->CapturedSourceTags.GetAggregatedTags();
			Message.Target = ULyraVerbMessageHelpers::GetPlayerStateFromObject(AbilitySystemComponent->GetAvatarActor());
			Message.TargetTags = *DamageEffectSpec->CapturedTargetTags.GetAggregatedTags();
			//@TODO: Fill out context tags, and any non-ability-system source/instigator tags
			//@TODO: Determine if it's an opposing team kill, self-own, team kill, etc...

			UGameplayMessageSubsystem& MessageSystem = UGameplayMessageSubsystem::Get(GetWorld());
			MessageSystem.BroadcastMessage(Message.Verb, Message);
		}

		//@TODO: assist messages (could compute from damage dealt elsewhere)?
		*/
	}

#endif // #if WITH_SERVER_CODE
}

void USimpleHealthComponent::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);

	DOREPLIFETIME(USimpleHealthComponent, DeathState);
}
