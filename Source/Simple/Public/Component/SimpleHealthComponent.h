// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "SimpleHealthComponent.generated.h"

struct FGameplayEffectSpec;

class USimpleHealthAttributeSet;
class USimpleAbilitySystemComponent;

UENUM(BlueprintType)
enum class ESimpleDeathState : uint8
{
	NotDead = 0,
	DeathStarted,
	DeathFinished
};

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FSimpleHealth_DeathEvent, AActor*, OwningActor);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_FourParams(FSimpleHealth_AttributeChanged, USimpleHealthComponent*, HealthComponent, float, OldValue, float, NewValue, AActor*, Instigator);

UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class SIMPLE_API USimpleHealthComponent : public UActorComponent
{
	GENERATED_BODY()

public:	
	USimpleHealthComponent();

	UFUNCTION(BlueprintCallable, Category = "Simple|Health")
	float GetHealth() const;

	UFUNCTION(BlueprintCallable, Category = "Simple|Health")
	float GetMaxHealth() const;

	// Returns the current health in the range [0.0, 1.0].
	UFUNCTION(BlueprintCallable, Category = "Simple|Health")
	float GetHealthNormalized() const;

protected:
	virtual void OnUnregister() override;
	void ClearGameplayTags();

public:	
	UFUNCTION(BlueprintCallable, Category = "Simple|Health")
	void InitializeWithAbilitySystem(USimpleAbilitySystemComponent* SimpleAbilitySystemComponent);

	// Uninitialize the component, clearing any references to the ability system.
	UFUNCTION(BlueprintCallable, Category = "Simple|Health")
	void UninitializeFromAbilitySystem();

	virtual void StartDeath();
	virtual void FinishDeath();

protected:
	UFUNCTION()
	virtual void OnRep_DeathState(ESimpleDeathState OldDeathState);

	virtual void HandleHealthChanged(AActor* DamageInstigator, AActor* DamageCauser, const FGameplayEffectSpec* DamageEffectSpec, float DamageMagnitude, float OldValue, float NewValue);
	virtual void HandleMaxHealthChanged(AActor* DamageInstigator, AActor* DamageCauser, const FGameplayEffectSpec* DamageEffectSpec, float DamageMagnitude, float OldValue, float NewValue);
	virtual void HandleOutOfHealth(AActor* DamageInstigator, AActor* DamageCauser, const FGameplayEffectSpec* DamageEffectSpec, float DamageMagnitude, float OldValue, float NewValue);
public:
	UPROPERTY(BlueprintAssignable)
	FSimpleHealth_AttributeChanged OnHealthChanged;

	UPROPERTY(BlueprintAssignable)
	FSimpleHealth_AttributeChanged OnMaxHealthChanged;

	UPROPERTY(BlueprintAssignable)
	FSimpleHealth_DeathEvent OnDeathStarted;

	UPROPERTY(BlueprintAssignable)
	FSimpleHealth_DeathEvent OnDeathFinished;

protected:
	UPROPERTY()
	TObjectPtr<USimpleAbilitySystemComponent> AbilitySystemComponent;

	UPROPERTY()
	TObjectPtr<const USimpleHealthAttributeSet> SimpleHealthAttributeSet;

	UPROPERTY(ReplicatedUsing = OnRep_DeathState)
	ESimpleDeathState DeathState;
};
