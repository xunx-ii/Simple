// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AbilitySystemComponent.h"
#include "Abilities/AttributeSets/SimpleAttributeSet.h"
#include "SimpleHealthAttributeSet.generated.h"

/**
 * 
 */
UCLASS()
class SIMPLE_API USimpleHealthAttributeSet : public USimpleAttributeSet
{
	GENERATED_BODY()
public:

	USimpleHealthAttributeSet();

	ATTRIBUTE_ACCESSORS(USimpleHealthAttributeSet, Health);
	ATTRIBUTE_ACCESSORS(USimpleHealthAttributeSet, MaxHealth);

	mutable FSimpleAttributeEvent OnHealthChanged;
	mutable FSimpleAttributeEvent OnMaxHealthChanged;
	mutable FSimpleAttributeEvent OnOutOfHealth;

protected:

	UFUNCTION()
	void OnRep_Health(const FGameplayAttributeData& OldValue);

	UFUNCTION()
	void OnRep_MaxHealth(const FGameplayAttributeData& OldValue);

	void ClampAttribute(const FGameplayAttribute& Attribute, float& NewValue) const;

	virtual bool PreGameplayEffectExecute(FGameplayEffectModCallbackData& Data) override;
	virtual void PostGameplayEffectExecute(const FGameplayEffectModCallbackData& Data) override;

	virtual void PreAttributeBaseChange(const FGameplayAttribute& Attribute, float& NewValue) const override;
	virtual void PreAttributeChange(const FGameplayAttribute& Attribute, float& NewValue) override;

	virtual void PostAttributeChange(const FGameplayAttribute& Attribute, float OldValue, float NewValue) override;

private:

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_Health, Category = "Simple|Health", Meta = (HideFromModifiers, AllowPrivateAccess = true))
	FGameplayAttributeData Health;

	UPROPERTY(BlueprintReadOnly, ReplicatedUsing = OnRep_MaxHealth, Category = "Simple|Health", Meta = (AllowPrivateAccess = true))
	FGameplayAttributeData MaxHealth;

	bool bOutOfHealth;
	float MaxHealthBeforeAttributeChange;
	float HealthBeforeAttributeChange;
};
