// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Abilities/GameplayAbility.h"
#include "SimpleGameplayAbility.generated.h"

UENUM(BlueprintType)
enum class ESimpleAbilityActivationPolicy : uint8
{
	// Try to activate the ability when the input is triggered.
	OnInputTriggered,

	// Continually try to activate the ability while the input is active.
	WhileInputActive,
};

UCLASS()
class SIMPLE_API USimpleGameplayAbility : public UGameplayAbility
{
	GENERATED_BODY()
public:
	USimpleGameplayAbility();

	ESimpleAbilityActivationPolicy GetActivationPolicy() const { return ActivationPolicy; }

protected:
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Lyra|Ability Activation")
	ESimpleAbilityActivationPolicy ActivationPolicy;
};
